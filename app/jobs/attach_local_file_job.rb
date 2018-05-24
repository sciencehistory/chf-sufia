# Converts an UploadedFile into a FileSet and attaches it to works.
# Modified from sufia AttachFilesToWorkJob, to be a single file at a time.
#
# https://github.com/samvera/sufia/blob/v7.4.0/app/jobs/attach_files_to_work_job.rb
#
# See overview in coordinator class, our local app/actors/sufia//create_with_files_actor.rb.
class AttachLocalFileJob < ActiveJob::Base
  queue_as :ingest


  # @param [ActiveFedora::Base] the work class
  # @param [Array<UploadedFile>] an array of files to attach
  def perform(work, uploaded_file)
    file_set = FileSet.new
    user = User.find_by_user_key(work.depositor)
    actor = CurationConcerns::Actors::FileSetActor.new(file_set, user)
    actor.create_metadata(work, visibility: work.visibility) do |file|
      file.permissions_attributes = work.permissions.map(&:to_hash)
    end

    attach_content(actor, uploaded_file.file)
    uploaded_file.update(file_set_uri: file_set.uri)
  end

  private

  # @param [CurationConcerns::Actors::FileSetActor] actor
  # @param [UploadedFileUploader] file
  def attach_content(actor, file)
    case file.file
    when CarrierWave::SanitizedFile
      actor.create_content(file.file.to_file)
    when CarrierWave::Storage::Fog::File
      # Not sure why this ever happens, this whole branch should only be triggered
      # for local files not remote files, but this was in original AttachFilesToWorkJob (where
      # I also can't figure out why it would ever be triggered), so we'll keep it.
      import_url(actor, file)
    else
      raise ArgumentError, "Unknown type of file #{file.class}"
    end
  end

  # Unlike original AttachFilesToWorkJob#import_url, we _perform_now_, to avoid
  # more hard to keep track of async. we're already in a job for a single file,
  # we can just do it sync.
  #
  # @param [CurationConcerns::Actors::FileSetActor] actor
  # @param [UploadedFileUploader] file
  def import_url(actor, file)
    actor.file_set.update(import_url: file.url)
    log = CurationConcerns::Operation.create!(user: actor.user,
                                              operation_type: "Attach File")

    ImportUrlJob.perform_now(actor.file_set, log)
  end


end
