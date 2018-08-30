class MemberConversionController < ApplicationController
  # Promote a FileSet to a child GenericWork.
  # Note: this saves the parent FileSet and the new child work *twice each*.
  # The hard part here is trying to do this as performant as we can, with as few saves as
  # we can, proper locking, etc. This stack makes this HARD.
  def to_child_work
    begin
      parent_work = GenericWork.find(params['parentid'])
      file_set = FileSet.find(params['filesetid'])
    rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone, ActiveFedora::RecordInvalid
      flash[:notice] = "Sorry. This item no longer exists."
      redirect_to "/works/#{parent_work.id}"
      return
    end
    if !self.class.can_promote_to_child_work?(current_user, parent_work, file_set)
      flash[:notice] = "\"#{file_set.title.first}\" can't be promoted to a child work."
      redirect_to "/concern/parent/#{parent_work.id}/file_sets/#{file_set.id}"
      return
    end
    #Validation is now out of the way.


    # Create the new child work and transfer all the metadata from its parent.
    new_child_work = create_intermediary_child_work(parent_work, file_set)

    # Deal with member relationships in bg job cause it's SO SLOW. remove fileset, add child work
    # in some place, add collection to new child work.
    FilesetToWorkCompletionJob.perform_later(parent_work.id, child_work_id: new_child_work.id, file_set_id: file_set.id)

    flash[:notice] = "\"#{new_child_work.title.first}\" is IN PROCESS of promotion from file set to child work, in \"#{parent_work.title.first}\". You can edit it immediately."
    redirect_to edit_curation_concerns_generic_work_path(new_child_work.id)
  end


  # Demote a child work to a file set.
  # This deletes the child work.
  def to_fileset
    begin
      parent_work = GenericWork.find(params['parentworkid'] )
      child_work = GenericWork.find(params['childworkid'] )
    rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone, ActiveFedora::RecordInvalid
      flash[:notice] = "This item no longer exists, so it can't be promoted to a child work."
      redirect_to "/works/#{parent_work.id}"
      return
    end
    if !self.class.can_demote_to_file_set?(current_user, parent_work, child_work)
      flash[:notice] = "Sorry. \"#{child_work.title.first}\" can't be demoted to a file."
      redirect_to "/works/#{child_work.id}"
      return
    end

    WorkToFilesetCompletionJob.perform_later(parent_work.id, child_work_id: child_work.id)

    file_set = child_work.members.first

    flash[:notice] = "\"#{file_set.title.first}\" is IN PROCESS of being demoted to a file attached to \"#{parent_work.title.first}\". All metadata associated with the child work has been deleted. You can edit the file immediately if desired."
    redirect_to "/concern/parent/#{parent_work.id}/file_sets/#{file_set.id}"
  end

  private

  # Creates child work with:
  # * All the appropriate metadata copied from parent
  # * title/creator copied from file_set
  # * file_set set as member of new child_work
  #
  # DOES save the new child work.
  # DOES NOT actually add it to parent_work yet. That's expensive and needs to be done
  # in a lock.
  # DOES NOT transfer collection membership, that's a whole different mess.
  def create_intermediary_child_work(parent, file_set)
    new_child_work = GenericWork.new(title: file_set.title, creator: [current_user.user_key])
    new_child_work.apply_depositor_metadata(current_user.user_key)
    # make original fileset a member of our new child work
    self.class.add_to_parent(new_child_work, file_set, 0, make_thumbnail: true, make_representative: true)

    # and set the child work's metadata based on the parent work.

    # bibliographic
    attrs_to_copy = parent.attributes.sort.map { |a| a[0] }
    attrs_to_copy -= ['id', "title", 'lease_id', 'embargo_id', 'head', 'tail', 'access_control_id', 'thumbnail_id', 'representative_id' ]
    attrs_to_copy.each do |a|
      new_child_work[a] = parent[a]
    end

    # permissions-related
    new_child_work.visibility = parent.visibility
    new_child_work.embargo_release_date = parent.embargo_release_date
    new_child_work.lease_expiration_date = parent.lease_expiration_date
    parent_permissions = parent.permissions.map(&:to_hash)

    # member HAS to be saved to set it's permission attributes, not sure why.
    # extra saves make things extra slow. :(
    new_child_work.save!
    if parent_permissions.present?
      new_child_work.permissions_attributes = parent_permissions
    end
    # But now everything seems to be properly saved without need for another save.
    return new_child_work
  end



  ###
  # Some utility methods implemented as class-methods so they can be used anywhere if needed.
  # We use in our jobs classes. Trying to keep this well-organized and DRY despite the crazy
  # code we need to deal with terrible performance splitting things into various classes.
  ##


  def self.transfer_collection_membership(parent, member)
    locker = ObjectLocker.new
    look_up_collection_ids(parent.id).each do |c_id|
      locker.acquire_lock_for(c_id) do
        c = Collection.find(c_id)
        c.members.push(member)
        c.save!
      end
    end
  end

  # We need an object that includes CurationConcerns::Lockable, so we can use it's
  # redis-based pessmismistic lock behavior in transfer_collection_membership.
  # Kind of annoying API from CurationConcerns.
  class ObjectLocker
    include CurationConcerns::Lockable
  end



  # Remove a fileset or child work from a parent work.
  # If the fileset or child work happened to be
  # the thumbnail or representative, set that value to nil.
  def self.remove_member_from_parent(parent, member)
    parent.ordered_members.delete(member)
    parent.members.delete(member)
  end

  # Add a fileset or generic work to a parent work's list of members.
  # If requested, reset the thumbnail or representative to the new item.
  #
  # Does _not_ call save on anything -- not sure, member changing may trigger it's own save under the hood
  def self.add_to_parent(parent, member, place_in_order, make_representative:, make_thumbnail:)
    parent.ordered_members.insert_at(place_in_order, member)
    # ordered_members seems to take care of this for us, if tests still pass...
    #parent.members.push(member)
    if make_representative
      parent.representative_id = member.id
    end
    if make_thumbnail
      parent.thumbnail_id = member.id
    end
  end




  def self.can_promote_to_child_work?(user, parent, member)
    [
      (parent.is_a? GenericWork),
      (member.is_a? FileSet),
      (self.check_connection(parent, member)),
      (user.can?(:edit, member.id)),
      (user.can?(:edit, parent.id)),
    ].all?
  end

  def self.can_demote_to_file_set?(user, parent, member)
    [ (parent.is_a? GenericWork),
      (member.is_a? GenericWork),
      (self.look_up_parent_work_ids(member.id).count == 1),
      (self.check_connection(parent, member)),
      (member.members.to_a.count == 1),
      (member.ordered_members.to_a.count == 1),
      (member.members.first.is_a? FileSet),
      (user.can?(:destroy, member.id)),
      (user.can?(:edit, parent.id)),
    ].all?
  end

  def self.check_connection(parent, member)
    # avoid actually fetching members, which kind of only helps if
    # we don't have to fetch them later anyway, which we may but we're
    # trying, so we use fancy solr technique...

    [ (parent != nil), (member != nil),
      look_up_parent_work_ids(member.id).include?(parent.id),
    ].all?
  end

  def self.look_up_collection_ids(id)
    self.look_up_container_ids(id, 'Collection')
  end

  def self.look_up_parent_work_ids(id)
    self.look_up_container_ids(id, 'GenericWork')
  end

  """
  Search SOLR for items that contain this item in their member_ids_ssim field.
  This is used both to store the collection-item relationship, but also the parent-child relationship.
  This is adapted from:
  https://github.com/samvera/curation_concerns/blob/v1.7.8/app/presenters/curation_concerns/work_show_presenter.rb#L92
  """
  def self.look_up_container_ids(id, container_model)
    solr = ActiveFedora::SolrService
    q = "{!field f=member_ids_ssim}#{id}"
    solr.query(q, fl:'id,has_model_ssim', fq: "has_model_ssim:#{container_model}")
      .map    { |x| x.fetch('id') }
  end

end
