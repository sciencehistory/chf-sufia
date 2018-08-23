class MemberConversionController < ApplicationController
  include CurationConcerns::Lockable

  # Promote a FileSet to a child GenericWork.
  # Note: this saves the parent FileSet and the new child work *twice each*.
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

    place_in_order = parent_work.ordered_members.to_a.find_index(file_set)
    # Was the fileset we are promoting serving as the thumbnail or representative?
    thumb_or_rep = get_thumbnail_and_rep_status(parent_work, file_set)
    # Create the new child work and transfer all the metadata from its parent.
    new_child_work = GenericWork.new(title: file_set.title, creator: [current_user.user_key])
    new_child_work.apply_depositor_metadata(current_user.user_key)
    # Add the fileset to the child work ...
    add_to_parent(new_child_work, file_set, 0, {:thumb => true, :rep => true} )
    # and set the child work's metadata based on the parent work.
    copy_metadata_from_parent(parent_work, new_child_work)
    acquire_lock_for(parent_work.id) do
        # Detach the fileset from the parent ...
        remove_member_from_parent(parent_work, file_set, thumb_or_rep)
        # and attach the child work in its place.
        add_to_parent(parent_work, new_child_work, place_in_order, thumb_or_rep)
    end
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
    # Was the child work we're removing serving as the thumbnail or representative?
    # If so we'll replace it with the fileset.
    thumb_or_rep = get_thumbnail_and_rep_status(parent_work, child_work)
    file_set = child_work.members.first
    acquire_lock_for(parent_work.id) do
        # Detach the child work from the parent ...
        remove_member_from_parent(parent_work, child_work, thumb_or_rep)
        # and replace it with the fileset.
        add_to_parent(parent_work, file_set, place_in_order, thumb_or_rep)
    end
    # Now get rid of the child work.
    child_work.delete
    flash[:notice] = "\"#{file_set.title.first}\" has been demoted to a file attached to \"#{parent_work.title.first}\". All metadata associated with the child work has been deleted."
    redirect_to "/concern/parent/#{parent_work.id}/file_sets/#{file_set.id}"
  end

  private

  # A lot of the code in this controller hinges on whether a fileset
  # or work was the thumbnail or representative of a parent
  # work before it got deleted or moved. Instead of checking
  # every single time, store it in a hash and pass it around.
  def get_thumbnail_and_rep_status(parent, member)
    {
      :thumb => (parent.thumbnail      == member),
      :rep   => (parent.representative == member)
    }
  end

  # Add a fileset or generic work to a parent work's list of members.
  # If requested, reset the thumbnail or representative to the new item.
  def add_to_parent(parent, member, place_in_order, thumb_or_rep)
    parent.ordered_members = parent.ordered_members.to_a.insert(place_in_order, member)
    parent.members.push(member)
    if thumb_or_rep[:rep]
      parent.representative_id = member.id
      parent.representative = member
    end
    if thumb_or_rep[:thumb]
      parent.thumbnail_id = member.id
      parent.thumbnail = member
    end
    parent.save!
  end

  # Remove a fileset or child work from a parent work.
  # If the fileset or child work happened to be
  # the thumbnail or representative, set that value to nil.
  def remove_member_from_parent(parent, member, thumb_or_rep)
    parent.thumbnail_id = nil if thumb_or_rep[:thumb]
    parent.representative_id = nil if thumb_or_rep[:rep]
    parent.ordered_members.delete(member)
    parent.members.delete(member)
    parent.save!
  end

  def copy_metadata_from_parent(parent, member)
    # bibliographic
    attrs_to_copy = parent.attributes.sort.map { |a| a[0] }
    attrs_to_copy -= ['id', "title", 'lease_id', 'embargo_id', 'head', 'tail', 'access_control_id', 'thumbnail_id', 'representative_id' ]
    attrs_to_copy.each do |a|
      member[a] = parent[a]
    end

    # permissions-related
    member.visibility = parent.visibility
    member.embargo_release_date = parent.embargo_release_date
    member.lease_expiration_date = parent.lease_expiration_date
    parent_permissions = parent.permissions.map(&:to_hash)
    if parent_permissions.present?
      member.permissions_attributes = parent_permissions
    end

    # membership
    transfer_collection_membership(parent, member)
    member.save!
  end

  def transfer_collection_membership(parent, member)
      MemberHelper.look_up_collection_ids(parent.id).each do |c_id|
      c = Collection.find(c_id)
      c.members.push(member)
      c.save!
    end
  end

end