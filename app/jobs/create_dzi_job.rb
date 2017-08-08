require 'concurrent'

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

  #WORKING_DIR = CHF::Env.lookup(:dzi_job_working_dir)
  WORKING_DIR = "./tmp/dzi-job-working"
  UPLOAD_THREADS = 10000

  class_attribute :vips_command
  self.vips_command = "vips"

  class_attribute :jpeg_quality
  self.jpeg_quality = "85"

  attr_accessor :file_set
  attr_accessor :file_obj

  def perform(file_set_id, repo_file_type: "original_file")
    ensure_dirs

    @file_set = FileSet.find(file_set_id)
    @file_obj = file_set.send(repo_file_type)

    fetch_from_fedora!

    create_dzi!

    upload_to_s3!
  ensure
    clean_up_tmp_files
  end

  # CreateDziJob.new.url_for_dzi(file_id)
  def url_for_dzi(file_id:nil, checksum: nil)
    if checksum.nil?
      checksum = Hydra::PCDM::File.find(file_id).checksum.value
    end

    fog_directory.files.get(dzi_file_name).public_uri
  end

  protected

  def fetch_from_fedora!
    response = nil
    path = local_original_file_path
    uri = URI.parse(file_obj.uri.to_s)

    fedora_fetch_benchmark = Benchmark.measure do
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri

        http.request request do |response|
          open path, 'wb' do |io|
            response.read_body do |chunk|
              io.write chunk
            end
          end
        end
      end
    end
    Rails.logger.debug("#{self.class.name}: fetch_from_fedora: #{fedora_fetch_benchmark}")
    unless response.code == "200"
      raise StandardError.new("Could not fetch file from fedora: #{uri}")
    end
  end

  def create_dzi!
    dzi_benchmark = Benchmark.measure do
      system(vips_command, "dzsave", local_original_file_path, local_dzi_base_path, "--suffix", ".jpg[Q=#{jpeg_quality}]") or raise StandardError.new("vips dzsave failed")
    end
    Rails.logger.debug("#{self.class.name}: create_dzi: #{dzi_benchmark}")
  end

  # uploading to s3 is actually the slowest part if done serially.
  # We apply a healthy dose of concurrency.
  def upload_to_s3!
    s_time = Time.now
    begin
      file = File.open(local_dzi_file_path, "rb")
      # .dzi file
      fog_directory.files.create(
        key: dzi_file_name,
        body: file,
        public: true, # TODO auth
      )
    ensure
      file.close if file
    end

    futures = []

    dir_path = Pathname.new(local_dzi_dir_path)
    # All the jpgs, which are in a _files/ dir, and subdirs of that.
    Dir.glob("#{dir_path}/**/*.jpg").each do |full_path|
      # using the :io executor, we're gonna use as many threads as we have files.
      # That seems to be ok?
      futures << Concurrent::Future.execute(executor: :io) do
        begin
          thread_file = File.open(full_path, "rb")
          thread_key_path = Pathname.new(full_path).relative_path_from(Pathname.new(WORKING_DIR)).to_s
          fog_directory.files.create(
            key: thread_key_path,
            body: thread_file,
            public: true # todo AUTH
          )
        ensure
          thread_file.close if file
        end
      end
    end

    # wait on em all
    futures.collect(&:value)

    Rails.logger.debug("#{self.class.name}: upload_to_s3: #{Time.now - s_time}")


    # any errors? Raise one of em.
    if rejected = futures.find(&:rejected?)
      raise rejected.reason
    end
  end

  def self.thread_pool_executor
    @thread_pool ||= Concurrent::ThreadPoolExecutor.new(
        min_threads:     UPLOAD_THREADS,
        max_threads:     UPLOAD_THREADS,
        auto_terminate:  true,
        idletime:        60, # 1 minute. shouldn't matter, we have min and max the same
        max_queue:       0, # unlimited
        fallback_policy: :abort # shouldn't matter -- 0 max queue
    )
  end

  # include the checksum so it's self-cache-busting if file at this URL
  # changes, say, due to versioning.
  def base_file_name
    @base_file_name ||= CGI.escape "#{file_obj.id}_checksum#{file_obj.checksum.value}"
  end

  def dzi_file_name
    "#{base_file_name}.dzi"
  end


  def local_original_file_path
    @local_original_file_path ||= Pathname.new(WORKING_DIR).join("#{base_file_name}.original").to_s
  end

  def local_dzi_base_path
    @local_dzi_path || Pathname.new(WORKING_DIR).join(base_file_name).to_s
  end
  def local_dzi_file_path
    "#{local_dzi_base_path}.dzi"
  end
  def local_dzi_dir_path
    "#{local_dzi_base_path}_files"
  end

  def clean_up_tmp_files
    FileUtils.rm_rf([local_original_file_path, local_dzi_file_path, local_dzi_dir_path])
  end

  def ensure_dirs
    FileUtils.mkdir_p WORKING_DIR
  end

  def fog_connection
    @fog_connection = Fog::Storage.new({
      :provider                 => 'AWS',
      :region                   => "us-east-1",
      :aws_access_key_id        => "",
      :aws_secret_access_key    => ""
    })
  end

  def fog_directory
    # warning don't 'create' here if you can avoid it, AWS gets mad with too
    # many creates. bucket should already exist.
    @fog_directory ||= fog_connection.directories.get("chf-cache")
  end


end
