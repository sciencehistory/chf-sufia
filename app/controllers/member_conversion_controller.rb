class MemberConversionController < ApplicationController
  include CurationConcerns::Lockable

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
    if !MemberHelper.can_promote_to_child_work?(current_user, parent_work, file_set)
      flash[:notice] = "\"#{file_set.title.first}\" can't be promoted to a child work."
      redirect_to "/concern/parent/#{parent_work.id}/file_sets/#{file_set.id}"
      return
    end
    #Validation is now out of the way.


    # Create the new child work and transfer all the metadata from its parent.
    new_child_work = create_intermediary_child_work(parent_work, file_set)


    # figure out it's context in the parent, and swap em.

    place_in_order = parent_work.ordered_members.to_a.find_index(file_set)
    was_thumbnail = is_thumbnail?(parent_work, file_set)
    was_representative = is_representative?(parent_work, file_set)

    acquire_lock_for(parent_work.id) do
      # Detach the fileset from the parent ...
      remove_member_from_parent(parent_work, file_set)
      # and attach the child work in its place.
      add_to_parent(parent_work, new_child_work, place_in_order, make_thumbnail: was_thumbnail, make_representative: was_representative)
      parent_work.save!
    end


    # TODO needs lock on collections
    transfer_collection_membership(parent_work, new_child_work)

    flash[:notice] = "\"#{new_child_work.title.first}\" has been promoted to a child work of \"#{parent_work.title.first}\". Click \"Edit\" to adjust metadata."
    redirect_to "/works/#{new_child_work.id}"
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
    if !MemberHelper.can_demote_to_file_set?(current_user, parent_work, child_work)
      flash[:notice] = "Sorry. \"#{child_work.title.first}\" can't be demoted to a file."
      redirect_to "/works/#{child_work.id}"
      return
    end

    place_in_order = parent_work.ordered_members.to_a.find_index(child_work)
    was_thumbnail = is_thumbnail?(parent_work, child_work)
    was_representative = is_representative?(parent_work, child_work)

    file_set = child_work.members.first

    acquire_lock_for(parent_work.id) do
        # Detach the child work from the parent ...
        remove_member_from_parent(parent_work, child_work)
        # and replace it with the fileset.
        add_to_parent(parent_work, file_set, place_in_order, make_representative: was_representative, make_thumbnail: was_thumbnail)
        parent_work.save!
    end
    child_work.delete

    flash[:notice] = "\"#{file_set.title.first}\" has been demoted to a file attached to \"#{parent_work.title.first}\". All metadata associated with the child work has been deleted."
    redirect_to "/concern/parent/#{parent_work.id}/file_sets/#{file_set.id}"
  end

  private


  def is_thumbnail?(parent, member)
    parent.thumbnail      == member
  end

  def is_representative?(parent, member)
    parent.representative == member
  end

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
    add_to_parent(new_child_work, file_set, 0, make_thumbnail: true, make_representative: true)

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


  # Add a fileset or generic work to a parent work's list of members.
  # If requested, reset the thumbnail or representative to the new item.
  #
  # Does _not_ call save on anything -- not sure, member changing may trigger it's own save under the hood
  def add_to_parent(parent, member, place_in_order, make_representative:, make_thumbnail:)
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

  # Remove a fileset or child work from a parent work.
  # If the fileset or child work happened to be
  # the thumbnail or representative, set that value to nil.
  def remove_member_from_parent(parent, member)
    parent.ordered_members.delete(member)
    parent.members.delete(member)
  end


  def transfer_collection_membership(parent, member)
    MemberHelper.look_up_collection_ids(parent.id).each do |c_id|
      c = Collection.find(c_id)
      c.members.push(member)
      c.save!
    end
  end

end
