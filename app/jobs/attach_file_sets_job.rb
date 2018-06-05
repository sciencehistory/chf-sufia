# Part of our local refactor of the attaching jobs actors/jobs.
# See overview of our local refactor at local ./app/sufia/create_with_files_actor.rb,
# the class that is the entry point to refactored data flow.
#
# Actually attaching a fileset to a work needs to lock the work so only one thing
# is editing the work at once, since it requires a save of the entire work metadata to
# attach each file.
#
# So, we do it in ONE job that attaches ALL filesets for multiple new additions, then
# triggers seperate jobs for actually adding the bytestreams to each new fileset -- since
# they don't require locking the work.
#
# Really, it would make sense to attach all new filesets and only save the work ONCE,
# but existing stack does a save of the work for each fileset, and it's too hard to change
# that now, would require copying/changing too much code. So we're sticking with it.
#


class AttachFileSetsJob < ActiveJob::Base
  include CurationConcerns::Lockable

  attr_reader :work, :uploaded_files, :remote_files, :user

  def perform(work, uploaded_files:, remote_files:, user:)
    @work, @uploaded_files, @remote_files, @user = work, (uploaded_files || []), (remote_files || []), user

    attach_local_files
    attach_remote_files
  end

  private

  # @return [TrueClass]
  def attach_local_files
    new_file_sets = []
    ingest_job_args = []

    uploaded_files.each do |uploaded_file|
      file_set = create_and_attach_file_set

      new_file_sets << file_set
      ingest_job_args << [file_set, uploaded_file, user]
    end

    # First add all filesets to work in _one_ work save.
    add_new_file_sets_to_work(new_file_sets)

    # Now launch jobs for them all. We previously tried launching jobs incrementally
    # before adding filesets to works, but found some jobstream jobs assumed filesets
    # were already attached to works, so even though this is not as efficient for throughput,
    # it's safer.
    ingest_job_args.each do |job_args|
      AttachLocalFileJob.perform_later(*job_args)
    end

    true
  end

  # Taken from CreateWithRemoteFilesActor#attach_files, but some logic moved into
  # our custom per-file job.
  def attach_remote_files
    new_file_sets = []
    ingest_job_args = []

    remote_files.each do |remote_file_info|
      next if remote_file_info.blank? || remote_file_info[:url].blank?

      file_set = create_file_set(import_url: remote_file_info[:url], label: remote_file_info[:file_name])

      new_file_sets << file_set
      ingest_job_args << [file_set, remote_file_info, user]
    end

    # First add all filesets to work in _one_ work save.
    add_new_file_sets_to_work(new_file_sets)

    # Now launch jobs for them all. We previously tried launching jobs incrementally
    # before adding filesets to works, but found some jobstream jobs assumed filesets
    # were already attached to works, so even though this is not as efficient for throughput,
    # it's safer.
    ingest_job_args.each do |job_args|
      AttachRemoteFileJob.perform_later(*job_args)
    end

    true
  end

  def add_new_file_sets_to_work(new_file_sets)
   return unless new_file_sets.present?

    acquire_lock_for(work.id) do
      work.reload unless work.new_record?

      new_file_sets.each do |file_set|
        work.ordered_members << file_set
      end

      if work.representative_id.blank?
        work.representative = new_file_sets.first
      end
      if work.thumbnail_id.blank?
        work.thumbnail = new_file_sets.first
      end

      work.save!
    end
  end

  # Creates FileSet with metadata for our purposes, and saves it.
  # does _not_ attach to work yet. Does _not_ attach bytestream yet.
  # Trying to make performance for these operations reasonable by splitting
  # up what operations are done when more reasonably and things aren't done multiple
  # times that only need to be done once (like saving the work)
  #
  # Extracted from FileSetActor#create_metadata as well as things in default stock
  # actor/jobs.
  # https://github.com/samvera/curation_concerns/blob/v1.7.8/app/actors/curation_concerns/actors/file_set_actor.rb
  def create_file_set(import_url: nil, label: nil)
    file_set = FileSet.new(import_url: import_url, label: label)

    file_set.apply_depositor_metadata(user)
    now = CurationConcerns::TimeService.time_in_utc
    file_set.date_uploaded = now
    file_set.date_modified = now
    file_set.creator = [user.user_key]

    visibility_params = {
      visbility: work.visibility,
      embargo_release_date: work.embargo_release_date,
      lease_expiration_date: work.lease_expiration_date
    }.compact
    if visibility_params.present?
      CurationConcerns::Actors::ActorStack.new(file_set, user, [CurationConcerns::Actors::InterpretVisibilityActor]).create(visibility_params)
    end

    file_set.permissions_attributes = work.permissions.map(&:to_hash)

    file_set.save!

    return file_set
  end
end
