module CHF
  # Generate URLs backed by an pre-generated assets on s3.
  # DZIs, or our new custom style of derivatives created by CreateDerivativesOnS3Service
  #
  # Supports tile_source_url, thumb_url.
  class DziS3UrlService
    attr_reader :file_id, :checksum, :file_set_id
    def initialize(file_set_id:, file_id:, checksum:)
      @file_id = file_id
      @checksum = checksum
      @file_set_id = file_set_id
    end

    def tile_source_url
      CreateDziService.s3_dzi_url_for(file_id: file_id, checksum: checksum)
    end

    def thumb_url(size:, density_descriptor: nil)
      CreateDerivativesOnS3Service.s3_url(file_set_id: file_set_id, file_checksum: checksum, filename_key: size_to_thumbnail_filename_key(size: size, density_descriptor: density_descriptor), suffix: ".jpg")
    end

    # We have 1x and 2x statically generated.
    def thumb_srcset_pixel_density(size:)
      "#{thumb_url(size: size)} 1x, #{thumb_url(size: size, density_descriptor: '2X')} 2x"
    end

    # filename_base, if provided, is used to make more human-readable
    # 'save as' download file names.
    def download_options(filename_base: nil)
      [
        {
          option_key: "small",
          url: Rails.application.routes.url_helpers.s3_download_redirect_path(file_set_id, "dl_small", filename_base: filename_base)
        },
        {
          option_key: "medium",
          url: Rails.application.routes.url_helpers.s3_download_redirect_path(file_set_id, "dl_medium", filename_base: filename_base)
        },
        {
          option_key: "large",
          url: Rails.application.routes.url_helpers.s3_download_redirect_path(file_set_id, "dl_large", filename_base: filename_base)
        },
        {
          option_key: "full",
          url: Rails.application.routes.url_helpers.s3_download_redirect_path(file_set_id, "dl_full_size", filename_base: filename_base)
        }
      ]
    end

    protected

    def size_to_thumbnail_filename_key(size: size, density_descriptor: nil)
      # gah we used two different vocabularies sorry
      filename_key = case size.to_s
        when "mini"
          "thumb_mini"
        when "standard"
          "thumb_standard"
        when "large"
          "thumb_hero"
        else
          raise ArgumentError.new("unrecognized size key: #{size.to_s}")
      end
      if density_descriptor
        filename_key += "_#{density_descriptor}"
      end

      filename_key
    end

  end
end
