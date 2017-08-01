module CHF
  module Utils
    # Ping the riiif server with a HEAD info request for a given file id, to trigger
    # caching of original asset on riiif server.
    #
    # You need config :iiif_internal_url set, for instance maybe IIIF_INTERNAL_URL=http://localhost:3000
    # if you really want to ping your dev server.
    #
    #     CHF::Utils::IiifOriginalPreloader.new(file_id).ping_to_preload
    #
    # NOTE: This does no auth, so will not work on non-public images
    class IiifOriginalPreloader
      include ImageServiceHelper

      attr_reader :file_id, :riiif_base
      def initialize(file_id, riiif_base: CHF::Env.lookup(:iiif_internal_url))
        @file_id = file_id
        @riiif_base = riiif_base
        unless riiif_base.present?
          raise ArgumentError, "Need an :iiif_internal_url config. Can set in env with, e.g., IIIF_INTERNAL_URL=http://localhost:3000/image-service"
        end
      end

      # Returns Faraday::Response
      def ping_to_preload
        conn = Faraday.new(riiif_base)
        conn.head ping_path
      end

      def ping_path
        path_prefix = Addressable::URI.parse(riiif_base).path # may have terminal slash, may not
        path_prefix << '/' if path_prefix[-1] != '/' # ensure terminal slash
        path_prefix + "#{CGI.escape(file_id)}/info.json"
      end
    end
  end
end
