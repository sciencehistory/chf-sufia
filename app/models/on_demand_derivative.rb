# Tracks derivatives that are created on demand, and then cached in a store.
# The store is expected to be purged periodically, which the db is not told about,
# so the actual file may not exist.
#
# This model is responsible for determining the file name, created from work id
# and checksum, so if the checksum changes, we'll look for a new file and not
# use the old one (which will then be eventually purged by the store)
#
# this is for the moment used for work-wide derivatives. PDF and Zip.
#
# These are generally created by the OnDemandDerivativesController
class OnDemandDerivative < ApplicationRecord
  # Still in progress, and hasn't been touched in this long? Give up and restart
  STALE_IN_PROGRESS_SECONDS = 20.minutes
  # Error happened this long ago? Willing to try again.
  ERROR_RETRY_SECONDS = 10.minutes
  # Used when we're not storing on S3, prob only for dev/test.
  LOCAL_FILE_PATH_BASE = Rails.root + "public"


  enum deriv_type: %w{pdf}.collect {|v| [v, v]}.to_h.freeze,
       status: %w{in_progress success error}.collect {|v| [v, v]}.to_h.freeze

  delegate :file_exists?, :url, :write_from_path, to: :resource_locator

  def file_name
    "#{work_id}_#{checksum}.pdf"
  end

  # Will go to solr to fetch.
  def work_presenter
    @work_presenter ||= CurationConcerns::GenericWorkShowPresenter.new(
      SolrDocument.find(work_id),
      Ability.new(nil)
    )
  end

  protected

  def resource_locator()
    @resource_locator ||= begin
      path_prefix = deriv_type
      if CHF::Env.lookup("derivatives_cache_bucket")
        S3File.new(self, CHF::Env.lookup("derivatives_cache_bucket"), path_prefix)
      else
        LocalFile.new(self, LOCAL_FILE_PATH_BASE, path_prefix)
      end
    end
  end


  class S3File
    def initialize(model, bucket_name, prefix)
      @model, @bucket_name, @prefix = model, bucket_name, prefix || ""
    end

    def file_exists?
      s3_bucket.object(key_path).exists?
    end

    # Signed url to s3, so we can set content-disposition with a good filename.
    # Do we need to make it expire at all? I dunno.
    def url
      @url ||= s3_bucket.object(key_path).presigned_url(:get,
        expires_in: 7.days.to_i,
        response_content_disposition: ApplicationHelper.encoding_safe_content_disposition(
          ImageServiceHelper.download_name(@model.work_presenter, suffix: "pdf")
        )
      )
    end

    def write_from_path(path)
      s3_bucket.object(key_path).upload_file(path)
    end

    protected
    def s3_bucket
      @bucket||= Aws::S3::Resource.new(
        credentials: Aws::Credentials.new(CHF::Env.lookup('aws_access_key_id'), CHF::Env.lookup('aws_secret_access_key')),
        region: CHF::Env.lookup('aws_region')
      ).bucket(@bucket_name)
    end

    def key_path
      @keypath ||= (Pathname.new(@prefix) + @model.file_name).to_s
    end
  end

  class LocalFile
    def initialize(model, file_path_base, prefix)
      @model, @file_path_base, @prefix = model, file_path_base, prefix || ""
    end

    def file_exists?
      filepath.exist?
    end

    # Assume it's in "public". Relative URL for now, do we need absolute? Prob
    # not, we don't really plan to use this in production anyway.
    def url
      filepath.sub( %r{\A#{Regexp.escape (Rails.root + "public").to_s}}, '').to_s
    end

    def write_from_path(path)
      FileUtils.mkdir_p filepath.dirname

      read_file = File.open(path, "rb")
      write_file = File.open(filepath, "wb")

      IO.copy_stream(read_file, write_file)
    ensure
      read_file.close if read_file
      write_file.close if write_file
    end

    protected
    def filepath
      @filepath ||= Pathname.new(@file_path_base) + @prefix + @model.file_name
    end
  end


end
