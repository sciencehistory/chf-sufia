module CHF
  # Generate URLs backed by an IIIF server. Idea is we can make other
  # classes with same API to polymorphically switch on image server
  # type in image_service_helper.  Make a shared spec for expected API?
  class IiifUrlService
    attr_reader :file_id, :checksum
    def initialize(file_set_id:, file_id:, checksum: nil)
      @file_id = file_id
      # We ignore file_set_id and checksum at present, don't use it in URLs
    end

    def thumb_url(size:)
      iiif_image_url(format: "jpg", size: "#{ImageServiceHelper::THUMB_BASE_WIDTHS[size]},")
    end

    # On show page, we just use pixel density source set, passing in the LARGEST width needed for
    # any responsiveness page layout. Sends somewhat more bytes when needed at some responsive
    # sizes, but way simpler to implement; keep from asking riiiif for even more varying resizes;
    # prob good enough.
    def thumb_srcset_pixel_density(size:)
      base_width = ImageServiceHelper::THUMB_BASE_WIDTHS[size]
      [1, BigDecimal.new('1.5'), 2, 3, 4].collect do |multiplier|
        iiif_image_url(format: "jpg", size: "#{base_width * multiplier},") + " #{multiplier}x"
      end.join(", ")
    end

    def tile_source_url
      iiif_info_url
    end

    def download_options(filename_base: nil)
      # filename_base is ignored for this adapter at present, not really supported
      # by IIIF.
      [
        {
          option_key: "small",
          url: iiif_image_url(format: "jpg", size: "#{ImageServerHelper::DOWNLOAD_WIDTHS[:small]}")
        },
        {
          option_key: "medium",
          url: iiif_image_url(format: "jpg", size: "#{ImageServerHelper::DOWNLOAD_WIDTHS[:medium]}")
        },
        {
          option_key: "large",
          url: iiif_image_url(format: "jpg", size: "#{ImageServerHelper::DOWNLOAD_WIDTHS[:large]}")
        },
        {
          option_key: "full",
          url: iiif_image_url(format: "jpg", size: "full")
        }
      ]
    end

    protected # Might make these public? But they aren't part of our polymorphic API.

    # Returns the IIIF info.json document, suitable as an OpenSeadragon tile source/
    def iiif_info_url
      create_iiif_url("#{CGI.escape(file_id)}/info.json")
    end

    # Request an image URL from the iiif server. Format, size, and quality
    # arguments are optional, but must be formatted for IIIF api.
    # May make sense to make cover methods on top of this one
    # for specific images in specific places.
    #
    # Defaults copied from riiif defaults. https://github.com/curationexperts/riiif/blob/67ff0c49af198ba6afcf66d3db9d3d36a8694023/lib/riiif/routes.rb#L21
    def iiif_image_url(format: 'jpg', size: "full", quality: 'default')
      # Make these args some day? For now servs as documentation:
      region = 'full'
      rotation = '0'
      create_iiif_url("#{CGI.escape(file_id)}/#{region}/#{size}/#{rotation}/#{quality}.#{format}")
    end

    private

    def iiif_public_url_addressable
      @iiif_public_url_addressable ||= Addressable::URI.parse(CHF::Env.lookup(:iiif_public_url)).tap do |addressable|
        raise "CHF::Env iiif_public_url requires a valid URL with host and path, eg `http://example.com/image-service` or `//12.345.67.89/iiif/2`" if addressable.host.nil?
        unless addressable.path[-1] == ("/")
          # Make sure path ends in slash so relative joins will work as we need
          addressable.path = addressable.path + "/"
        end
      end
    end

    def create_iiif_url(path)
      return iiif_public_url_addressable.join(path).to_s
    end

  end
end
