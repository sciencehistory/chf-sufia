module CHF
  # Generate URLs backed by an pre-generated assets on s3.
  # Currently can't do thumbs or other derivatives, just viewer dzi
  class DziS3UrlService
    attr_reader :file_id, :checksum
    def initialize(file_id, checksum:)
      @file_id = file_id
      @checksum = checksum
    end


    def tile_source_url
      CreateDziService.s3_dzi_url_for(file_id: file_id, checksum: checksum)
    end

  end
end
