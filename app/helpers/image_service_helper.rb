module ImageServiceHelper
  THUMB_BASE_WIDTHS = {
    mini: 54,
    large: 525,
    standard: 208
  }.freeze

  DOWNLOAD_WIDTHS = {
    large: 2880,
    medium: 1200,
    small: 800
  }.freeze

  def default_image(member:)
    # image supplied by curation concerns or something, we should
    # prob find a better one.
    asset_path("nope.png")
  end


  def member_src_attributes(member:, size_key:)
    raise ArgumentError.new("Unrecognized size key: #{size_key}") unless THUMB_BASE_WIDTHS.keys.include?(size_key.to_sym)

    if member.representative_file_id.nil?
      # if there's no image, default
      {
        src:  default_image(member: member)
      }
    elsif service = _image_url_service(CHF::Env.lookup(:image_server_for_thumbnails), member)
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

    unless THUMB_BASE_WIDTHS.keys.include?(size_key)
      raise ArgumentError.new("Unrecognized size_key '#{size_key}'. Allowable: #{THUMB_BASE_WIDTHS.keys}")
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

    image_tag(args.delete(:src) || "", args)
  end

  def tile_source_url(member_presenter)
    if service = _image_url_service(CHF::Env.lookup(:image_server_on_viewer), member_presenter)
      service.tile_source_url
    else
      {"type" => "image", "url" => main_app.download_path(member_presenter.representative_id, file: "jpeg")}.to_json
    end
  end

  # filename_base, if provided, is used to make more human-readable
  # 'save as' download file names.
  def download_options(member_presenter, filename_base: nil)
    orig_width = member_presenter.representative_width
    orig_height = member_presenter.representative_height

    direct_original = {
      option_key: "original",
      label: "Original file",
      subhead: ("TIFF — #{orig_width} x #{orig_height}px" if orig_width && orig_height),
      analyticsAction: "download_original",
      url: main_app.download_path(member_presenter.representative_file_set_id)
    }

    if service = _image_url_service(CHF::Env.lookup(:image_server_downloads), member_presenter)

      service.download_options(filename_base: filename_base).tap do |list|
        unless list.any? {|h| h[:option_key] == "original" }
          list << direct_original
        end
      end.collect do |option|
        _fill_out_download_option(member_presenter, option)
      end
    else
      [direct_original]
    end
  end


  # returns config for the viewer, an array of JSON-able hashes, one for each image
  # included in this work to be viewed.
  def viewer_images_info(work_presenter)
    work_presenter.viewable_member_presenters.to_a.collect.with_index do |member_presenter, i|
      member_src_attributes_mini = member_src_attributes(member: member_presenter, size_key: :mini)
      {
        thumbHeight: member_proportional_height(member_presenter),
        index: i + 1,
        memberShouldShowInfo: member_presenter.model_name.to_s != "FileSet",
        title: member_presenter.link_name,
        memberId: member_presenter.representative_id,
        memberShowUrl: contextual_path(member_presenter, work_presenter),
        tileSource: tile_source_url(member_presenter),
        fallbackTileSource: {type: "image", url: main_app.download_path(member_presenter.representative_file_set_id , file: "jpeg")},
        thumbSrc: member_src_attributes_mini[:src],
        thumbSrcset: member_src_attributes_mini[:srcset],

        # downloads for this image only
        downloads: download_options(member_presenter, filename_base: _download_name_base(work_presenter, item_id: member_presenter.id))
      } if member_presenter.representative_file_id # don't show it in the viewer if there's no image
    end
  end

  private

  # Returns nil if no image service available. Otherwise an image
  # service that has tile_source_url, thumb_url, etc., methods.
  def _image_url_service(service_type, member)
    if service_type == "iiif"
      CHF::IiifUrlService.new(file_set_id: member.representative_file_set_id, file_id: member.representative_file_id, checksum: member.representative_checksum)
    elsif service_type == "dzi_s3"
      CHF::DziS3UrlService.new(file_set_id: member.representative_file_set_id, file_id: member.representative_file_id, checksum: member.representative_checksum)
    elsif (!service_type) || service_type == "false"
      nil
    else
      raise ArgumentError.new("Unrecognized image service type: #{service_type}")
    end
  end

  def _fill_out_download_option(member_presenter, option)
    orig_width = member_presenter.representative_width
    orig_height = member_presenter.representative_height

    values_for_keys = {
      small: {
        label: "Small JPG",
        analyticsAction: "download_jpg_small",
        width: ImageServiceHelper::DOWNLOAD_WIDTHS[:small],
      },
      medium: {
        label: "Medium JPG",
        analyticsAction: "download_jpg_medium",
        width: ImageServiceHelper::DOWNLOAD_WIDTHS[:medium]
      },
      large: {
        label: "Large JPG",
        analyticsAction: "download_jpg_large",
        width: ImageServiceHelper::DOWNLOAD_WIDTHS[:large]
      },
      full: {
        label: "Full-sized JPG",
        analyticsAction: "download_jpg_full",
        width: orig_width
      }
    }

    defaults = values_for_keys[option[:option_key].to_sym]
    option.reverse_merge!(defaults) if defaults

    width = option[:width]
    if width && orig_width
      height =  ((orig_height.to_d / orig_width) * width).round
      option[:subhead] ||= "#{width} x #{height}px"
    end

    return option
  end

  # Used for constructing download filenames when we can.
  # truncated first three words, plus id.
  #
  # Wanted to include the 'index number' for better sortability when
  # downloading multiple pages, but got too hard to actually keep track of/calculate
  # depending on access path.
  def _download_name_base(work, item_id:)
    three_words = Array(work.title).first.gsub(/[']/, '').gsub(/([[:space:]]|[[:punct:]])+/, ' ').split.slice(0..2).join('_').downcase[0..25]

    "#{three_words}_#{work.id}_#{item_id}"
  end

end
