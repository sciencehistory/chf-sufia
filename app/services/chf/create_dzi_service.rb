require 'concurrent'
require 'aws-sdk'


module CHF
  # Needs 'vips' installed.
  # Will overwrite if it's already there on S3 (or other fog destination)
  #
  # s3 bucket needs CORS turned on! http://docs.aws.amazon.com/AmazonS3/latest/user-guide/add-cors-configuration.html
  #
  # For performance, pass in just a file_id, it's all we need, we try to avoid lookups,
  # but if you can pass in a checksum that you got cheaply, you'll avoid us having to get
  # it expensively.
  #
  # Uses a bunch of Chf::Env settings:
  # required:
  #  * aws_access_key_id
  #  * aws_secret_access_key
  # optional (cause they have defaults):
  #  * dzi_job_tmp_dir
  #  * dzi_s3_bucket
  #  * dzi_s3_bucket_region
  #
  #
  # TODO some cleverer concurrency stuff if two of these jobs try acting at the same
  # time, keep the out of using each others files, or let them actually share/wait
  # on each other files.
  class CreateDziService
    WORKING_DIR = CHF::Env.lookup(:dzi_job_tmp_dir)
    UPLOAD_THREADS = 128

    class_attribute :vips_command
    self.vips_command = "vips"

    class_attribute :jpeg_quality
    self.jpeg_quality = "85"

    attr_accessor :file_id
    attr_accessor :checksum

    def initialize(file_id, checksum: nil)
      @file_id = file_id
      @checksum = checksum
    end

    # Downloads datastream and creates DZI files in WORKING_DIR,
    # uploads them to S3.
    def call
      ensure_dirs

      fetch_from_fedora!

      create_dzi!

      upload_to_s3!
    ensure
      clean_up_tmp_files
    end


    protected

    # Fetch Hydra::PCDM::File from fedora and save to WORKING_DIR,
    # streaming for efficiency.
    def fetch_from_fedora!
      response = nil
      # We hope this is the right way to get the actual uri to fetch?
      uri = URI.parse(FileSet.translate_id_to_uri.call(file_id))

      fedora_fetch_benchmark = Benchmark.measure do
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new uri

          http.request request do |response|
            open local_original_file_path, 'wb' do |io|
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
      # begin
      #   file = File.open(local_dzi_file_path, "rb")
      #   # .dzi file
      #   fog_directory.files.create(
      #     key: dzi_file_name,
      #     body: file,
      #     public: true, # TODO auth
      #   )
      # ensure
      #   file.close if file
      # end

      s3_bucket.
        object(dzi_file_name).
        upload_file(local_dzi_file_path, acl:'public-read')


      # All the jpgs, which are in a _files/ dir, and subdirs of that.
      futures = []
      dir_path = Pathname.new(local_dzi_dir_path)
      path_prefix_re = /\A#{Regexp.quote(WORKING_DIR.end_with?('/') ? WORKING_DIR : WORKING_DIR + '/')}/

      Dir.glob("#{dir_path}/**/*.jpg").each do |full_path|
        # using the :io executor, we're gonna use as many threads as we have files.
        # That seems to be ok?
        futures << Concurrent::Future.execute(executor: self.class.thread_pool_executor) do
          s3_bucket.
            object(full_path.sub(path_prefix_re, '')).
            upload_file(full_path, acl:'public-read')
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
    self.thread_pool_executor # init now

    # include the checksum so it's self-cache-busting if file at this URL
    # changes, say, due to versioning. HOWEVER, this does make indexing
    # somewhat slower. TODO optimize somehow. Less fetches to fedora and/or get
    # from solr.
    def base_file_name
      @base_file_name ||= CGI.escape "#{file_id}_checksum#{checksum}"
    end

    # If not already set, we have to fetch from fedora, which is kinda slow with AF.
    # TODO, we can make this one fetch, not two.
    def checksum
      @checksum || Hydra::PCDM::File.find(file_id).checksum.value
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


    # Using Aws::S3 directly appeared to give us a lot faster bulk upload
    # than via fog.
    def s3_bucket
      @s3_bucket ||= Aws::S3::Resource.new(
        credentials: Aws::Credentials.new(CHF::Env.lookup('aws_access_key_id'), CHF::Env.lookup('aws_secret_access_key')),
        region: CHF::Env.lookup('dzi_s3_bucket_region')
      ).bucket(CHF::Env.lookup('dzi_s3_bucket'))
    end
  end
end
