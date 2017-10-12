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
class CreateDerivativesJob < ActiveJob::Base
  queue_as "jobs_server" # queue so we know we can run it on separate non-app server

  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the CurationConcerns.config.working_path
  def perform(file_set, file_id, _filepath = nil)
    CHF::CreateDerivativesOnS3Service.new(file_set, file_id).call
  end
end
