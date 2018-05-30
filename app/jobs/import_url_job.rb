# Override of sufia ImportUrlJob based on Hyrax master ImportUrlJob, to:
#
# * get correct name into system for files
# * _not_ create file as a temp file, so it's still THERE
#
# This version actually taken from scholarsphere:
# https://github.com/psu-stewardship/scholarsphere/blob/1222a615569fa9b8a1acc0017352935f85aad25a/app/jobs/import_url_job.rb
#
# TODO: get file to be cleaned up somehow after characterization/derivatives.
#
# Original sufia job: https://github.com/samvera/curation_concerns/blob/v1.7.8/app/jobs/import_url_job.rb
# hyrax version: https://github.com/samvera/hyrax/blob/b096d86761a4b768214f9d369ebf51ef46768bea/app/jobs/import_url_job.rb
#


# Overrides the CurationConcerns job to accept the remote file's original name and handle failures.
#
# The file is downloaded using its original name and extension, but sanitized with CarrierWave to
# remove any non-alphanumeric characters. This is the same process that occurs with locally
# uploaded files (via CarrierWave) and avoids problems later when interacting with filenames
# that have unsupported characters.
#
# Additionally, if the job encounters any issues when downloading the file, such as an expired
# url or a timeout, the file set's name is changed to reflect the error.

require 'uri'
require 'tempfile'
require 'browse_everything/retriever'

class ImportUrlJob < ActiveJob::Base
  queue_as CurationConcerns.config.ingest_queue_name

  before_enqueue do |job|
    log = job.arguments.last
    log.pending_job(job)
  end

  # @param [FileSet] file_set
  # @param [String] file_name
  # @param [CurationConcerns::Operation] log to send messages
  def perform(file_set, file_name, log)
    file_name ||= file_set.import_url && File.basename(URI.parse(file_set.import_url).path)

    log.performing!
    user = User.find_by_user_key(file_set.depositor)
    File.open(File.join(Dir.tmpdir, CarrierWave::SanitizedFile.new(file_name).filename), 'wb') do |f|
      importer = UrlImporter.new(file_set.import_url, f)
      importer.copy_remote_file

      unless importer.success?
        file_set.title = [I18n.t('scholarsphere.import_url.failed_title', file_name: file_name)]
        file_set.errors.add(
          'Error:',
          I18n.t('scholarsphere.import_url.failed_message', link: file_link(file_name, file_set.id),
                                                            message: importer.error)
        )
        on_error(log, file_set, user)
        return false
      end

      file_set.reload

      if CurationConcerns::Actors::FileSetActor.new(file_set, user).create_content(f)
        CurationConcerns.config.callback.run(:after_import_url_success, file_set, user)
        log.success!
      else
        on_error(log, file_set, user)
      end
    end
  end

  protected

    def on_error(log, file_set, user)
      CurationConcerns.config.callback.run(:after_import_url_failure, file_set, user)
      log.fail!(file_set.errors.full_messages.join(' '))
    end

    def file_link(file_name, id)
      ActionController::Base.helpers.link_to(
        file_name,
        Rails.application.routes.url_helpers.curation_concerns_file_set_path(id)
      )
    end

    class UrlImporter
      attr_reader :url, :file, :error

      # @param [String] url
      # @param [File] file
      def initialize(url, file)
        @url = url
        @file = file
      end

      def success?
        error == nil
      end



      # @return [Boolean]
      # Downloads the remote file from the url to the file
      def copy_remote_file
        file.binmode
        retriever = BrowseEverything::Retriever.new
        retriever.retrieve('url' => url) { |chunk| file.write(chunk) }
        file.rewind
        true
      rescue StandardError => e
        @error = e.message
        false
      end
    end
end
