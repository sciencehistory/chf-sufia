# We have functionality in MemberConversionController to change a child work into just
# a fileset, by deleting the child work and atatching the fileset directly to the parent,
# in the same order in the member list.
#
# This is so slow that we need to do some of it in the bg though. This job does the actual swapping
# out of things in parent member list, and deleting of the unwanted child work.
#
#
# This CAN run on separate jobs server.
class WorkToFilesetCompletionJob < ActiveJob::Base
  include CurationConcerns::Lockable

  queue_as :jobs_server

  def perform(parent_id, child_work_id:)
    parent_work = GenericWork.find(parent_id)
    child_work  = GenericWork.find(child_work_id)

    # Should we be validating? We already validated in controller before kicking off
    # job, that's probably good enough for at least our actual use cases.

    place_in_order = parent_work.ordered_members.to_a.find_index(child_work)
    was_thumbnail = is_thumbnail?(parent_work, child_work)
    was_representative = is_representative?(parent_work, child_work)

    file_set = child_work.members.first

    acquire_lock_for(parent_work.id) do
        # Detach the child work from the parent ...
        MemberConversionController.remove_member_from_parent(parent_work, child_work)
        # and replace it with the fileset.
        MemberConversionController.add_to_parent(parent_work, file_set, place_in_order, make_representative: was_representative, make_thumbnail: was_thumbnail)
        parent_work.save!
    end
    child_work.delete
  end

  private

  def is_thumbnail?(parent, member)
    parent.thumbnail      == member
  end

  def is_representative?(parent, member)
    parent.representative == member
  end

end
