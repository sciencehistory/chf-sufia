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
  queue_as :jobs_server

  def perform(parent_id, child_work_id:)
    child_work = nil
    acquire_lock_for(parent_id) do
      parent_work = GenericWork.find(parent_id)
      child_work  = GenericWork.find(child_work_id)

      # Should we be validating? We already validated in controller before kicking off
      # job, that's probably good enough for at least our actual use cases.

      place_in_order = parent_work.ordered_members.to_a.find_index(child_work)
      was_thumbnail = is_thumbnail?(parent_work, child_work)
      was_representative = is_representative?(parent_work, child_work)

      file_set = child_work.members.first


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


  # Copied from https://github.com/samvera/curation_concerns/blob/0001cbde69aa3d234dadce1bb78bc9b578be43bc/app/services/curation_concerns/lockable.rb
  # but we need to customize timeouts in #lock_manager. Same code copy pasted into fileset_to_work_completion_job.rb, maybe
  # we should extract into module.
  def acquire_lock_for(lock_key, &block)
    lock_manager.lock(lock_key, &block)
  end

  def lock_manager
    # ttl, retry_count, delay
    # TTL in ms, needs to be longer than the maximum we think this might take, a LONG TIME, and
    # we might be behind a couple of them. :(
    @lock_manager ||= CurationConcerns::LockManager.new(600000, 40, 25000)
  end
end
