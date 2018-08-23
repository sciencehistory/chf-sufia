class MemberConversionController < ApplicationController
  include CurationConcerns::Lockable

  #Promote a FileSet to a child GenericWork.
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
    place_in_order = parent_work.ordered_members.to_a.find_index(file_set)
    transfer_thumbnail = (parent_work.thumbnail == file_set)
    transfer_representative = (parent_work.representative == file_set)
    new_child_work = GenericWork.new(title: file_set.title)
    acquire_lock_for(parent_work.id) do
        new_child_work.apply_depositor_metadata(current_user.user_key)
        new_child_work.creator = [current_user.user_key]
        new_child_work.save!
        copy_metadata_from_parent(parent_work, new_child_work)
        parent_work.representative_id = nil if transfer_representative
        parent_work.thumbnail_id = nil if transfer_thumbnail
        remove_member_from_parent(parent_work, file_set)
        parent_work.save!
        add_member_to_parent(new_child_work, file_set, 0)
        set_thumbnail_and_rep(new_child_work, file_set, true, true)
        set_thumbnail_and_rep(parent_work, new_child_work, transfer_thumbnail, transfer_representative)
        new_child_work.save!
        add_member_to_parent(parent_work, new_child_work, place_in_order)
        parent_work.save!
    end
    flash[:notice] = "\"#{new_child_work.title.first}\" has been promoted to a child work of \"#{parent_work.title.first}\". Click \"Edit\" to adjust metadata."
    redirect_to "/works/#{new_child_work.id}"

  end

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
    transfer_thumbnail = (parent_work.thumbnail == child_work)
    transfer_representative = (parent_work.representative == child_work)
    file_set = child_work.members.first

    acquire_lock_for(parent_work.id) do
        parent_work.representative_id = nil if transfer_representative
        parent_work.thumbnail_id = nil if transfer_thumbnail
        remove_member_from_parent(parent_work, child_work)
        parent_work.save!
        add_member_to_parent(parent_work, file_set, place_in_order)
        set_thumbnail_and_rep(parent_work, file_set, transfer_thumbnail, transfer_representative)
        parent_work.save!
        child_work.delete
    end

    flash[:notice] = "\"#{file_set.title.first}\" has been demoted to a file attached to \"#{parent_work.title.first}\". All metadata associated with the child work has been deleted."
    redirect_to "/concern/parent/#{parent_work.id}/file_sets/#{file_set.id}"
  end

  private

  def add_member_to_parent(parent, member, place_in_order)
    parent.ordered_members = parent.ordered_members.to_a.insert(place_in_order, member)
    parent.members.push(member)
  end

  def remove_member_from_parent(parent, member)
    parent.ordered_members.delete(member)
    parent.members.delete(member)
  end

  def get_from_parent (parent, member_id)
    parent.members.to_a.find { |x| x.id == member_id }
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
  end

  def set_thumbnail_and_rep(parent, member, thumbnail, representative)
    if representative
      parent.representative_id = member.id
      parent.representative = member
    end
    if thumbnail
      parent.thumbnail_id = member.id
      parent.thumbnail = member
    end
  end

  def transfer_collection_membership(parent, member)
      MemberHelper.look_up_collection_ids(parent.id).each do |c_id|
      c = Collection.find(c_id)
      c.members.push(member)
      c.save!
    end
  end

end