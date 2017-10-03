module ImageServiceHelper
  BASE_WIDTHS = {
    large: 526,
    standard: 208
  }.freeze


  def member_src_attributes(member:, size_key:)
    if member.representative_file_id.nil?
      # if there's no image, show the default thumbnail if we have one (it gets indexed for some types of obj)
      {
        src:  member.try(:thumbnail_path)
      }
    elsif service = _representative_image_url_service(CHF::Env.lookup(:image_server_on_show_page), member)
      {
        src:    service.thumb_url(size: size_key),
        srcset: service.thumb_srcset_pixel_density(size: size_key)
      }
    elsif member.representative_file_set_id || member.representative_id
      # representative_file_set_id is the RIGHT one, but being defensive in case
      # only the other is in index, it will be the same thing MOST of the time.
      {
        src: main_app.download_path(member.representative_file_set_id || member.representative_id, file: "jpeg")
      }
    else
      # no can do
      {}
    end
  end

  # can only be used on a page that has the viewer listening
  def viewer_trigger_data_attributes(parent_id:, member:)
    {
      trigger: "chf_image_viewer",
      member_id: member.representative_id,
      analytics_category: "Work",
      analytics_action: "view",
      analytics_label: parent_id
    }
  end

  # create an image tag for a 'member' (could be fileset or child work) thumb,
  # for use on show page. Calculates proper image tag based on lazy or not,
  # use of iiif for images or not, and desired size. Includes proper
  # attributes for triggering viewer, analytics, etc.
  #
  # if use_image_server is false, size_key is ignored and no srcsets are generated,
  # we just use the stock hydra-derivative created image labelled 'jpeg'
  def member_image_tag(parent_id:, member:, size_key: nil, lazy: false)
    size_key = :standard if size_key.blank?

    unless BASE_WIDTHS.keys.include?(size_key)
      raise ArgumentError.new("Unrecognized size_key '#{size_key}'. Allowable: #{BASE_WIDTHS.keys}")
    end

    args = {
      class: ["show-page-image-image"],
      alt: "",
      tabindex: 0,
      data: {
        aspectratio: "#{member.representative_width}/#{member.representative_height}" # used for lazysizes-aspectratio
      }
    }

    src_args = member_src_attributes(member: member, size_key: size_key)

    if lazy
      args[:class] << "lazyload"
      args[:data].merge!(src_args)
    else
      args.merge!(src_args)
    end

    image_tag(args.delete(:src), args)
  end

  def tile_source_url(member_presenter)
    if service = _representative_image_url_service(CHF::Env.lookup(:image_server_on_viewer), member_presenter)
      service.tile_source_url
    else
      {"type" => "image", "url" => main_app.download_path(member_presenter.representative_id, file: "jpeg")}.to_json
    end
  end

  # Returns nil if none available
  def full_res_jpg_url(member_presenter)
    if service = _representative_image_url_service(CHF::Env.lookup(:image_server_downloads), member_presenter)
      service.full_res_jpg_url
    end
  end

  private

  # Returns nil if no image service available. Otherwise an image
  # service that has tile_source_url, thumb_url, etc., methods.
  def _representative_image_url_service(service_type, member)
    if service_type == "iiif"
      CHF::IiifUrlService.new(member.representative_file_id, checksum: member.representative_checksum)
    elsif service_type == "dzi_s3"
      CHF::DziS3UrlService.new(member.representative_file_id, checksum: member.representative_checksum)
    elsif (!service_type) || service_type == "false"
      nil
    else
      raise ArgumentError.new("Unrecognized image service type: #{service_type}")
    end
  end

end
