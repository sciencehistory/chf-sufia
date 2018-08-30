# We have functionality in MemberConversionController to change a fileset to a child
# work, by deleting the fileset, creating a new child work, and swapping it in.
#
# This is so slow that we need to do some of it in the bg though. This job assumes
# the new child work HAS ALREADY BEEN CREATED with correct metadata EXCEPT
# It is not yet actually a member of the parent, and does not have collection membership
# assigned either. Both of those things are too slow.
#
#
# This CAN run on separate jobs server.
class FilesetToWorkCompletionJob < ActiveJob::Base
  include CurationConcerns::Lockable

  queue_as :jobs_server

  def perform(parent_id, child_work_id:, file_set_id:)
    # Should we be validating? We already validated in controller before kicking off
    # job, that's probably good enough for at least our actual use cases.

    parent_work = GenericWork.find(parent_id)
    new_child_work  = GenericWork.find(child_work_id)
    file_set    = FileSet.find(file_set_id)


    # figure out it's context in the parent, and swap em.
    place_in_order = parent_work.ordered_members.to_a.find_index(file_set)
    was_thumbnail = is_thumbnail?(parent_work, file_set)
    was_representative = is_representative?(parent_work, file_set)

    acquire_lock_for(parent_work.id) do
      # Detach the fileset from the parent ...
      MemberConversionController.remove_member_from_parent(parent_work, file_set)
      # and attach the child work in its place.
      MemberConversionController.add_to_parent(parent_work, new_child_work, place_in_order, make_thumbnail: was_thumbnail, make_representative: was_representative)
      parent_work.save!
    end

    # TODO needs lock on collections?
    MemberConversionController.transfer_collection_membership(parent_work, new_child_work)
  end

  private

  def is_thumbnail?(parent, member)
    parent.thumbnail      == member
  end

  def is_representative?(parent, member)
    parent.representative == member
  end

end
