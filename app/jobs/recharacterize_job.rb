# Copy of https://github.com/samvera/curation_concerns/blob/v1.7.7/app/jobs/characterize_job.rb
#   with call to CreateDerivativesJob removed
#   and file cleanup added
#   Parameters to allow use of a local file have been removed so that we don't accidentally clean
#     up a file that wasn't intended to be a temp file.
#   It would be possible to clean up a temp file out from under another job, if another job happened to
#     be running on the same object at the same moment.
class RecharacterizeJob < ActiveJob::Base
  include CurationConcerns::Lockable

  queue_as CurationConcerns.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the CurationConcerns.config.working_path
  def perform(file_set, file_id)
    filename = CurationConcerns::WorkingDirectory.find_or_retrieve(file_id, file_set.id)
    raise LoadError, "#{file_set.class.characterization_proxy} was not found" unless file_set.characterization_proxy?

    # Prevent other jobs from trying to modify the FileSet at the same time
    acquire_lock_for(file_set.id) do
      Hydra::Works::CharacterizationService.run(file_set.characterization_proxy, filename)
      Rails.logger.debug "Ran characterization on #{file_set.characterization_proxy.id} (#{file_set.characterization_proxy.mime_type})"
      file_set.characterization_proxy.save!
      file_set.update_index
      file_set.parent.in_collections.each(&:update_index) if file_set.parent
    end
  ensure
    File.delete(filename)

    dir = File.split(filename).first
    cleanup_directory(dir)
  end

  # recursively delete parent directories if they are empty, but never delete root working directory
  # (These files are stored in 4-deep pairtrees)
  def cleanup_directory(dir)
    return if dir == CurationConcerns.config.working_path
    parent = File.split(dir).first
    if Dir["#{dir}/*"].empty?
      Dir.delete dir
      cleanup_directory parent
    end
  end
end
