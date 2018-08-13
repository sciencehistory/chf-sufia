require 'concurrent'
require 'aws-sdk-s3'

# Needs 'vips' installed.
# Will overwrite if it's already there on S3 (or other fog destination)
#
#
# s3 bucket needs CORS turned on! http://docs.aws.amazon.com/AmazonS3/latest/user-guide/add-cors-configuration.html
#
# TODO some cleverer concurrency stuff if two of these jobs try acting at the same
# time, keep the out of using each others files, or let them actually share/wait
# on each other files.
class CreateDziJob < ActiveJob::Base
  queue_as :dzi


  def perform(file_set_id, repo_file_type: "original_file")
    # It's a bit expensive to get all this stuff, is there a cheaper way
    # to get it from fedora? Or from Solr, and would that be reliable enough?
    file_set = FileSet.find(file_set_id)
    file_obj = file_set.send(repo_file_type) if file_set

    if ! file_obj.mime_type&.start_with?("image/")
      Rails.logger.warn("Skipping dzi creation for non-image file #{file_set_id}")
      return
    end

    if file_obj
      checksum = file_obj.checksum.value
      CHF::CreateDziService.new(file_obj.id, checksum: checksum).call
    else

      Rails.logger.warn("No original_file for #{file_set_id}? Could not push dzi")
    end
  end
end
