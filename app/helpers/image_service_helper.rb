# This helper module has gotten expansive, unfortunate Rails architecture
# of a bunch of global helper methods. Would be good to refactor into some
# more OO helper object, but hard to do in Rails and good enough for now.
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

  PLACEHOLDER_IMAGE_PATH = "placeholderbox.svg"

  def default_image(member:)
    asset_path(PLACEHOLDER_IMAGE_PATH)
  end


  # Returns a HASH of attributes, not just a url, becuase sometimes we need a srcset
  # as well as a src.
  def member_src_attributes(member:, size_key:)
    raise ArgumentError.new("Unrecognized size key: #{size_key}") unless THUMB_BASE_WIDTHS.keys.include?(size_key.to_sym)

    if member.representative_file_id.nil?
      # if there's no image, default
      {
        src:  default_image(member: member)
      }
    else
      service = _image_url_service(CHF::Env.lookup(:image_server_for_thumbnails), member)
      {
        src:    service.thumb_url(size: size_key),
        srcset: service.thumb_srcset_pixel_density(size: size_key)
      }
    end
  end

  # can only be used on a page that has the viewer listening
  def viewer_trigger_data_attributes(parent_id:, member:)
    return {} unless member

    if member.representative_content_type&.start_with?("image/")
      # trigger the viewer
      {
        trigger: "chf_image_viewer",
        member_id: member.representative_id,
        analytics_category: "Work",
        analytics_action: "view",
        analytics_label: parent_id
      }
    else
      # trigger a direct load of object in browser
      {
        trigger: "chf_view_original",
        href: main_app.download_path(member.representative_file_set_id, disposition: "inline")
      }
    end
  end

  # create an image tag for a 'member' (could be fileset or child work) thumb,
  # for use on show page. Calculates proper image tag based on lazy or not,
  # use of iiif for images or not, and desired size. Includes proper
  # attributes for triggering viewer, analytics, etc.
  #
  # if use_image_server is false, size_key is ignored and no srcsets are generated,
  # we just use the stock hydra-derivative created image labelled 'jpeg'
  def member_image_tag(parent_id:, member:, size_key: nil, lazy: false)
    return default_image(member: nil) if member.nil?

    size_key = :standard if size_key.blank?

    unless THUMB_BASE_WIDTHS.keys.include?(size_key)
      raise ArgumentError.new("Unrecognized size_key '#{size_key}'. Allowable: #{THUMB_BASE_WIDTHS.keys}")
    end

    args = {
      class: ["show-page-image-image"],
      alt: "",
      tabindex: 0,
      data: {
        # used for lazysizes-aspectratio
        aspectratio: ("#{member.representative_width}/#{member.representative_height}" if member)
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


  # Create an HTML5 tag for a FileSet or ChildWork.
  def member_audio_tag(parent_id:, member:)
    return default_image(member: nil) if member.nil?
    mp3_url =  CHF::AudioDerivativeMaker.s3_url(file_set_id:member.id, file_checksum:member.representative_checksum, type_key: :standard_mp3)
    webm_url = CHF::AudioDerivativeMaker.s3_url(file_set_id:member.id, file_checksum:member.representative_checksum, type_key: :standard_webm)

    result = "<h2 class=\"attribute-sub-head\">#{member.title.first}"
    if member.title.first != member.label
      result += " (#{member.label })"
    end
    result += "</h2>"
    result += "<audio controls controlsList=\"nodownload\">"
    result += "    <source src=\"#{mp3_url}\"  type=\"audio/mpeg\" />"
    result += "    <source src=\"#{webm_url}\" type=\"audio/webm\" />"
    result += "    <p><a href=\"/downloads/#{ member.id }\">Original audio</a></p>"
    result += "</audio>"

    raw(result)
  end



  # For feeding to OpenSeadragon
  def tile_source_url(member_presenter)
    service = _image_url_service(CHF::Env.lookup(:image_server_on_viewer), member_presenter)
    service.tile_source_url
  end

  # Configuration hash that both the JS viewer and our normal show pages
  # use to determine what download options to offer.
  #
  # filename_base, if provided, is used to make more human-readable
  # 'save as' download file names.
  def download_options(member_presenter, filename_base: nil)
    orig_width = member_presenter.representative_width
    orig_height = member_presenter.representative_height
    orig_page_count = member_presenter.representative_page_count

    is_image = member_presenter.representative_content_type&.start_with?("image/")
    is_audio = member_presenter.representative_content_type&.start_with?("audio/")

    subhead = CHF::Util.humanized_content_type(member_presenter.representative_content_type)
    if orig_width && orig_height
      subhead += " — #{orig_width} x #{orig_height}px"
    end
    if orig_page_count
      subhead += " — #{orig_page_count} #{'page'.pluralize(orig_page_count.to_i)}"
    end

    direct_original = {
      option_key: "original",
      label: "Original file",
      subhead: subhead,
      analyticsAction: "download_original",
      url: main_app.download_path(member_presenter.representative_file_set_id)
    } if member_presenter.representative_file_set_id

    if is_image
      service = _image_url_service(CHF::Env.lookup(:image_server_downloads), member_presenter)
      image_server_download = service.download_options(filename_base: filename_base).tap do |list|
        unless list.any? {|h| h[:option_key] == "original" }
          (list << direct_original) if direct_original
        end
      end.collect do |option|
        _fill_out_download_option(member_presenter, option)
      end
      return image_server_download

    elsif is_audio
      mp3_url = Rails.application.routes.url_helpers.s3_download_redirect_path(
        member_presenter.id, 'standard_mp3',
        filename_base: filename_base.nil? ? member_presenter.id : filename_base,
        no_content_disposition: false
      )
      mp3_download_link = {
        option_key: "mp3",
        label: "Optimized MP3",
        subhead: subhead,
        analyticsAction: "download_mp3",
        url: mp3_url,
      }
      return [mp3_download_link, direct_original].compact

    else
      # we don't currently have alternate downloads for PDFs.
      return [direct_original].compact
    end
  end

  # "medium" at 1200px wide is a good size for social media shares
  def social_media_share_image_medium(member_presenter)
    # a better API than generating all download options might be good, but we don't got it, heh
    options = download_options(member_presenter)
    option = options.find {|o| o[:option_key] == "medium" } || options.first
    url = option && option[:url]

    if url
      # if it's relative, make it absolute
      parsed = Addressable::URI.parse(url)
      if parsed.relative?
        parsed = Addressable::URI.parse(main_app.root_url).join(parsed)
      end
      return parsed.to_s
    end
  end


  # returns config for the viewer, an array of JSON-able hashes, one for each image
  # included in this work to be viewed. Used by our HTTP response providing
  # config for the JS viewer.
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
    end.compact
  end

  # Returns an image  service that has tile_source_url, thumb_url, etc., methods.
  # Maybe the CHF::LegacyAssetUrlService that has legacy sufia behavior
  def self.image_url_service_class(service_type)
    if service_type == "iiif"
      CHF::IiifUrlService
    elsif service_type == "dzi_s3"
      CHF::DziS3UrlService
    elsif (!service_type) || service_type == "false"
      CHF::LegacyAssetUrlService
    else
      raise ArgumentError.new("Unrecognized image service type: #{service_type}")
    end
  end

  # Used for constructing download filenames when we can.
  # truncated first three words, plus id.
  #
  # Wanted to include the 'index number' for better sortability when
  # downloading multiple pages, but got too hard to actually keep track of/calculate
  # depending on access path.
  #
  # doesn't actually need to be a helper, let's make it a global module-method so we can use it
  # everywhere -- helper version below.
  def self._download_name_base(work, item_id: nil)
    three_words = Array(work.title).first.gsub(/[']/, '').gsub(/([[:space:]]|[[:punct:]])+/, ' ').split.slice(0..2).join('_').downcase[0..25]

    base = "#{three_words}_#{work.id}"
    base += "_#{item_id}" if item_id

    base
  end

  def _download_name_base(*args)
    ImageServiceHelper._download_name_base(*args)
  end

  def self.download_name(work, item_id: nil, suffix:)
    suffix = ".#{suffix}" unless suffix.start_with?('.')
    _download_name_base(work, item_id: item_id) + suffix
  end


  private

  def _image_url_service(service_type, member)
    klass = ImageServiceHelper.image_url_service_class(service_type)
    if klass
      return klass.new(file_set_id: member.representative_file_set_id, file_id: member.representative_file_id, checksum: member.representative_checksum)
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



end
