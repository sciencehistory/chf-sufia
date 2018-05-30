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
  attr_reader :work, :uploaded_files, :remote_files, :user

  def perform(work, uploaded_files:, remote_files:, user:)
    @work, @uploaded_files, @remote_files, @user = work, (uploaded_files || []), (remote_files || []), user

    attach_local_files
    attach_remote_files
  end

  private

  # @return [TrueClass]
  def attach_local_files
    uploaded_files.each do |uploaded_file|
      file_set = create_and_attach_file_set
      AttachLocalFileJob.perform_later(file_set, uploaded_file, user)
    end
    true
  end

  # Taken from CreateWithRemoteFilesActor#attach_files, but some logic moved into
  # our custom per-file job.
  def attach_remote_files
    remote_files.each do |remote_file_info|
      next if remote_file_info.blank? || remote_file_info[:url].blank?

      file_set = create_and_attach_file_set(import_url: remote_file_info[:url], label: remote_file_info[:file_name])
      AttachRemoteFileJob.perform_later(file_set, remote_file_info, user)
    end
    true
  end

  def create_and_attach_file_set(import_url: nil, label: nil)
    file_set = FileSet.new(import_url: import_url, label: label)

    actor = CurationConcerns::Actors::FileSetActor.new(file_set, user)
    actor.create_metadata(work, visibility: work.visibility) do |file|
      file.permissions_attributes = work.permissions.map(&:to_hash)
    end

    return file_set
  end

end
