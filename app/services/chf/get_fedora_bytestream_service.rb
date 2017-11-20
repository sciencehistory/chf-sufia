module CHF
  # Given a file_id, streams the bytestream to local (server) file system.
  # Most of this logic is pretty fedora-independent, except we start with file_id,
  # and use fedora auth.
  #
  # returns a ruby File object.
  #
  # local_path = CHF::GetFedoraBytestreamService.new(file_id, local_path: '/somewhere/file').get
  #
  # At present you have to specify the local file path to write to, good idea to
  # put it in a directory created with Dir.mktmpdir or something.  It WILL overwrite
  # something that is there.
  #
  # This class will NOT clean it up for you, caller has got to clean it up itself
  # when done with it, really it has to! Don't fill up your file system!
  class GetFedoraBytestreamService
    class CouldNotFetchError < StandardError ; end

    attr_reader :file_id, :local_path

    def initialize(file_id, local_path:)
      @file_id = file_id
      @local_path = local_path
    end

    # returns actual URI object
    def fedora_uri
      # We hope this is the right way to get the actual uri to fetch cheaply?
      # a bit sketchy we're calling it on FileSet not File, but File doesn't
      # have this API, and it seems to work.
      @fedora_uri ||= URI.parse(FileSet.translate_id_to_uri.call(file_id))
    end

    def get
      response = nil

      fedora_fetch_benchmark = Benchmark.measure do
        response = Net::HTTP.start(fedora_uri.host, fedora_uri.port) do |http|
          request = Net::HTTP::Get.new fedora_uri

          if ActiveFedora.fedora.user || ActiveFedora.fedora.password
            request.basic_auth(ActiveFedora.fedora.user, ActiveFedora.fedora.password)
          end

          http.request request do |response|
            open local_path, 'wb' do |io|
              response.read_body do |chunk|
                io.write chunk
              end
            end
          end
        end
      end

      Rails.logger.debug("#{self.class.name}: fetch_from_fedora: #{fedora_fetch_benchmark}")

      unless response && response.code == "200"
        raise CouldNotFetchError.new("response: #{response}, uri: #{fedora_uri.to_s}")
      end
      return local_path
    end
  end
end
