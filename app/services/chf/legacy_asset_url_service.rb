module CHF
  # Generate asset URLs using default/legacy sufia methods that
  # don't require any extra dependencies (an S3 bucket, an IIIF server, etc)
  class LegacyAssetUrlService
    include Rails.application.routes.url_helpers

    attr_reader :file_id, :checksum, :file_set_id
    def initialize(file_set_id:, file_id:, checksum:)
      @file_id = file_id
      @checksum = checksum
      @file_set_id = file_set_id
    end

    def thumb_url(size:, density_descriptor: nil)
      file_arg = if size == "mini"
        "thumbnail"
      else
        "jpeg"
      end
      download_path(file_set_id, file: file_arg)
    end

    def member_src_attributes(member:, size_key:)
      if member.representative_file_set_id || member.representative_id
        {
          src: thumb_url(member: member, size: size_key)
        }
      else
        # no can do
        {}
      end
    end

    def tile_source_url(member_presenter)
      {"type" => "image", "url" => download_path(member_presenter.representative_id, file: "jpeg")}.to_json
    end

    # We only have a 1x
    def thumb_srcset_pixel_density(size:)
      "#{thumb_url(size: size)} 1x, #{thumb_url(size: size, density_descriptor: '2X')} 2x"
    end

    def download_options(filename_base: nil)
      []
    end
  end
end
