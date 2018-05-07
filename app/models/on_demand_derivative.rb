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


  enum deriv_type: %w{pdf zip}.collect {|v| [v, v]}.to_h.freeze,
       status: %w{in_progress success error}.collect {|v| [v, v]}.to_h.freeze

  delegate :file_exists?, :url, :write_from_path, to: :resource_locator

  class_attribute :job_class_for_type, instance_accessor: false
  self.job_class_for_type = {
    :pdf => CreateWorkPdfJob,
    :zip => CreateWorkZipJob
  }

  # Finds or creates the status record, and also kicks off the CreateWorkPdfJob in bg if status
  # requires it.
  #
  # Record created will have checksum in it, and old records with wrong checksum (cause members
  # have changed) will not be accepted -- will be deleted and re-created (in a concurrency-safe way).
  #
  # "Stale" records will also be deleted and recreated -- still in_progress that is way too old,
  # success but no actual derivative found, error that is old. New record created, bg job
  # kicked off for 'stale' records.
  #
  # optionally pass in `work_presenter:` if you already have it, saves us from having to
  # fetch and make it.
  #
  # retry_count is just for internal use to prevent infinite recursion in presence of a bug
  # that would otherwise result in it.
  def self.find_or_create_record(id, type, work_presenter: nil, checksum: nil, retry_count: 0)
    if retry_count > 10
      # what the heck is going on? Let's keep us from infinitely doing it and taking up all the CPU
      raise StandardError.new("Tried to find/create an OnDemandDerivative record too many times for work #{id}")
    end

    work_presenter ||= self.work_presenter(id)
    checksum ||= self.checksum_for_work(work_presenter)

    record = OnDemandDerivative.where(work_id: id, deriv_type: type).first
    if record.nil?
      record = OnDemandDerivative.create(work_id: id, deriv_type: type, status: :in_progress, checksum: checksum)
      self.job_class_for_type[type.to_sym].perform_later(record)
    end

    if ( record.in_progress? && (Time.now - record.updated_at) > OnDemandDerivative::STALE_IN_PROGRESS_SECONDS ) ||
       ( record.error? && (Time.now - record.updated_at) > OnDemandDerivative::ERROR_RETRY_SECONDS ) ||
       ( record.success? && (record.checksum != checksum || !record.file_exists? ))
          # It's stale, delete it!
          record.delete
          # and try again
          record = find_or_create_record(id, type,
            checksum: checksum,
            work_presenter: work_presenter,
            retry_count: retry_count + 1)
    end

    return record
  rescue ActiveRecord::RecordNotUnique
    # race condition, someone else created it, no biggy
    return find_or_create_record(id, type, checksum, retry_count: retry_count + 1)
  end

  # Will go to solr to fetch. Always creates presenter for non-logged-in-user.
  # Ideally all these class-methods should prob be extracted into a new object.
  def self.work_presenter(work_id)
    CurationConcerns::GenericWorkShowPresenter.new(
      SolrDocument.find(work_id),
      Ability.new(nil)
    )
  end

  # We gotta get all it's representatives, and compile all their checksums, to make
  # sure checksum changes if members have changed at all. This will be a couple
  # Solr fetches.
  #
  # Ideally all these class-methods should prob be extracted into a new object.
  def self.checksum_for_work(work_presenter)
    representative_checksums = work_presenter.public_member_presenters.collect(&:representative_checksum).compact
    Digest::MD5.hexdigest(representative_checksums.join("-"))
  end

  def file_suffix
    deriv_type
  end


  def file_name
    "#{work_id}_#{checksum}.#{file_suffix}"
  end

  def work_presenter
    @work_presenter = self.class.work_presenter(work_id)
  end

  protected

  def resource_locator()
    @resource_locator ||= begin
      path_prefix = deriv_type
      if CHF::Env.lookup("derivatives_cache_bucket")
        S3File.new(self, CHF::Env.lookup("derivatives_cache_bucket"), path_prefix, file_suffix)
      else
        LocalFile.new(self, LOCAL_FILE_PATH_BASE, path_prefix)
      end
    end
  end


  class S3File
    def initialize(model, bucket_name, prefix, suffix)
      @model, @bucket_name, @prefix, @suffix = model, bucket_name, prefix || "", suffix
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
          ImageServiceHelper.download_name(@model.work_presenter, suffix: @suffix)
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
