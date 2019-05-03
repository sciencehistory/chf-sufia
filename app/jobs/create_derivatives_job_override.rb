# Commpletely overridden, from scratch, from CurationConcerns.
# https://github.com/samvera/curation_concerns/blob/v1.7.8/app/jobs/create_derivatives_job.rb

# We completely reimplement ourselves. the existing implementation was not
# super useful, although we copy and paste some parts. We want to:
# 1) Assume runnning on a server NOT the app server, get file from fedora
# 2) push to S3
# 3) Make sure to clean up temp file(s)
# 4) Use optimal settings for a small sized thumbnail
#
# This has to be called AFTER the file is really added to fedora, _should_ be
# because of how it's called by sufia 7 stack.
# See https://bibwild.wordpress.com/2017/07/11/on-hooking-into-sufiahyrax-after-file-has-been-uploaded/
#     https://github.com/samvera/curation_concerns/blob/1d5246ebb8bccae0a385280eda10a7dbdc1d517d/app/jobs/characterize_job.rb#L22
#
# Also provides some class methods for file name calculation.

module CreateDerivativesJobOverride
  def create_derivatives_mode=(v)
    @create_derivatives_mode = v
  end

  def create_derivatives_mode
    @create_derivatives_mode ||= CHF::Env.lookup(:create_derivatives_mode) || "legacy"
  end

  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the CurationConcerns.config.working_path
  def perform(file_set, file_id, filepath = nil)
    # hack for dev
    create_derivatives_mode =  "dzi_s3"
    # end hack for dev
    if create_derivatives_mode == "dzi_s3"
      # Doesn't use filepath, it's gonna fetch from fedora, and clean up after itself
      CHF::CreateDerivativesOnS3Service.new(file_set, file_id).call
    elsif create_derivatives_mode == "legacy"
      super
    end
  ensure
    # Very hacky way to TRY to clean up temporary working files, which the stack does not.
    # May not get everything, we hope (and it seems?) not to get things that might still be in use
    # after this -- after derivatives, no other jobs want it. We hope.
    #
    # Different parts of the stack (or maybe just our local customizatons) seem to sometimems make working
    # copies on file_set.id, sometimes on file_set.original_file.id. :(
    filename = Hydra::PCDM::File.find(file_id).try(:original_name)
    if filename
      [
        CurationConcerns::WorkingDirectory.send(:full_filename, file_id, filename),
        CurationConcerns::WorkingDirectory.send(:full_filename, file_set.id, filename)
      ].each do |working_copy_path|
        FileUtils.rm_f(working_copy_path) if working_copy_path && working_copy_path.start_with?(CurationConcerns.config.working_path)
      end
    end
  end
end




CreateDerivativesJob.class_eval do
  if CHF::Env.lookup(:create_derivatives_mode) == "dzi_s3"
    queue_as "jobs_server" # queue so we know we can run it on separate non-app server
  end

  prepend CreateDerivativesJobOverride
end
