module CHF
  module Utils
    # Ping the riiif server with a HEAD info request for a given file id, to trigger
    # caching of original asset on riiif server.
    #
    # You need config :public_riiif_url set, for instance maybe PUBLIC_RIIIF_URL=http://localhost:3000
    # if you really want to ping your dev server.
    #
    # Even in production, you may want to set it to the internal AWS IP, for instance
    # on command line before running chf:riiif:preload_originals task.
    #
    #     CHF::Utils::RiiifOriginalPreloader.new(file_id).ping_to_preload
    class RiiifOriginalPreloader
      include RiiifHelper

      attr_reader :file_id
      def initialize(file_id)
        @file_id = file_id
      end

      def ping_to_preload
        Faraday.head ping_url
      end

      def ping_url
        unless CHF::Env.lookup(:public_riiif_url).present?
          raise ArgumentError, "We need a config :public_riiif_url to know where to ping. In dev, you could set ENV PUBLIC_RIIIF_URL=http://localhost:3000 if correct"
        end

        # The RiiifHelper#riiif_info_url method doesn't work here, because
        # of the way engine route helpers are being called from that context. :(
        # But we can still use it's #create_riiif_url method to add the
        # proper hostname according to config.
        create_riiif_url(Riiif::Engine.routes.url_helpers.info_path(file_id, locale: nil))
      end
    end
  end
end
