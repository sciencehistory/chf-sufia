module ImageServiceHelper
  BASE_WIDTHS = {
    large: 526,
    standard: 208
  }.freeze


  # create an image tag for a 'member' (could be fileset or child work) thumb,
  # for use on show page. Calculates proper image tag based on lazy or not,
  # use of iiif for images or not, and desired size. Includes proper
  # attributes for triggering viewer, analytics, etc.
  #
  # if use_image_server is false, size_key is ignored and no srcsets are generated,
  # we just use the stock hydra-derivative created image labelled 'jpeg'
  def member_image_tag(parent_id:, member:, size_key: :standard, lazy: false)
    unless BASE_WIDTHS.keys.include?(size_key)
      raise ArgumentError.new("Unrecognized size_key '#{size_key}'. Allowable: #{BASE_WIDTHS.keys}")
    end

    args = {
      class: ["show-page-image-image"],
      alt: "",
      data: {
        trigger: "chf_image_viewer",
        member_id: member.representative_id,
        aspectratio: "#{member.representative_width}/#{member.representative_height}", # used for lazysizes-aspectratio
        analytics_category: "Work",
        analytics_action: "view",
        analytics_label: parent_id
      }
    }

    src_args = if member.representative_file_id.nil?
      # if there's no image, show the default thumbnail (it gets indexed)
      {
        src:  member.thumbnail_path
      }
    elsif CHF::Env.lookup(:use_image_server_on_show_page)
      {
        src:    CHF::IiifUrlService.new(member.representative_file_id).thumb_url(size: size_key),
        srcset: CHF::IiifUrlService.new(member.representative_file_id).thumb_srcset_pixel_density(size: size_key)
      }
    else
      {
        src: main_app.download_path(member.representative_id, file: "jpeg")
      }
    end

    if lazy
      args[:class] << "lazyload"
      args[:data].merge!(src_args)
    else
      args.merge!(src_args)
    end

    image_tag(args.delete(:src), args)
  end

  def tile_source_url(member_presenter)
    if CHF::Env.lookup(:use_image_server_on_viewer)
      CHF::IiifUrlService.new(member_presenter.representative_file_id).tile_source_url
    else
      {"type" => "image", "url" => main_app.download_path(member_presenter.representative_id, file: "jpeg")}.to_json
    end
  end

  # Returns nil if none available
  def full_res_jpg_url(member_presenter)
    if CHF::Env.lookup(:use_image_server_downloads)
      CHF::IiifUrlService.new(member_presenter.representative_file_id).full_res_jpg_url
    end
  end
end
