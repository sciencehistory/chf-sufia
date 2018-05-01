# We're going to try to create a PDF of (roughly?) A4 (US letter) size, but
# the embedded images may be higher resolution for printing and/or retina viewing.
# A4 at 300dpi (fairly standard print resolution) is 2480 pixels x 3508 pixels
#
# Multiple images in a given work may have different aspect ratios --
# even when pages from the same book, due to our current production processes.
# So that complicates things somewhat.
#
# note if there is a work-member child has more than one image, we only include
# the one representative one at the moment, just like in viewer.
#
# note: will take a couple trips to solr to get what it needs. And then download
# jpgs to make the PDF. Can def be slow.
#
# ## Sizes
#
# We want to produce PDFs that are reasonable to read on screen, and ideally to print,
# at decent resolution, without being too enormous files -- for all our diverse images,
# with varying aspect ratios.
#
# prawn seems to do do it's coordinates in 72dpi (or maybe that's a PDF thing),
# but printers print at at least 300dpi (sometimes more), and displays these days
# are usually 100dpi and up (up to 300+ for high-res mobile).
#
# We are targetting US Letter size pages for convenient printing, and perhaps reasonable
# display in various PDF readers, desktop and mobile.
#
# * US Letter size, 612x792px at 72dpi (which is what prawn uses for it's coordinates).
# * US letter is 2550x3300 at 300dpi -- most printers are higher than that, even budget printers are 300dpi these days.
#
# For now we are using dl_medium size images, which are at 1200px _width_ regardless of image
# aspect ratio. For portrait-orientation pages, that ends up being about 150dpi, but it can
# end up much lower for REALLY wide images which have been resized a higher percentage to get
# into 1200px width. dl_large size images created 2GB PDF for Ramelli; dl_medium much more
# reasonable 300MB even for ramelli.
#
# Callback arg is any object that accepts `call(progress_i:, progress_total:)`, usually
# proc object.
module CHF
  class WorkPdfCreator
    PAGE_WIDTH = 612
    PAGE_HEIGHT = 792

    attr_reader :work_id
    def initialize(work_id)
      @work_id = work_id
    end

    def write_pdf_to_path(filepath, callback: nil)
      make_prawn_pdf(callback: callback).render_file(filepath)
    end

    def write_pdf_to_stream(io, callback: nil)
      io.write make_prawn_pdf(callback: callback).render
    end

    # you probably want {#write_pdf} instead. We intentionally write to disk
    # to not use huge RAM for our potentially huge PDFs.
    def make_prawn_pdf(callback: nil)
      pdf = Prawn::Document.new(
        margin: 0,
        skip_page_creation: true,
        page_size: [PAGE_WIDTH, PAGE_HEIGHT],
        layout: "portrait",
        # PDF metadata woot
        info: {
          Title: work_presenter.title.try(:first),
          Creator: "Science History Institute",
          Producer: "Science History Institute",
          CreationDate: Time.now,
          # for lack of a better PDF tag...
          Subject: "#{CHF::Env.lookup!(:app_url_base)}/works/#{work_id}",
          # not a standard PDF tag, but we'll throw it in
          Url: "#{CHF::Env.lookup!(:app_url_base)}/works/#{work_id}",
          Description: "Foo bar"
        }
      )

      count = image_info_list.count

      image_info_list.each_with_index do |image_info, index|
        embed_width, embed_height = image_embed_dimensions(image_info)
        # If they were missing, we do our best
        embed_width ||= PAGE_WIDTH
        embed_height ||= PAGE_HEIGHT

        pdf.start_new_page(size: [embed_width, embed_height], margin: 0)


        pdf.image open(url_or_path_for_image(image_info), "rb"), vposition: :center, position: :center, fit: [embed_width, embed_height]

        if callback
          callback.call(progress_total: count, progress_i: index + 1)
        end
      end

      return pdf
    end

    protected

    # We want to fit the image on an 8.5x11 page, expressed in prawn's 72 dpi coordinates.
    # At the moment, instead of actually marking a page as 'landscape' orientation (which would
    # require rotating the image), we'll allow the page to be EITHER 8.5x11 or 11x8.5. This might
    # cause weirdness if someone wants to print, we may improve later -- but MacOS Preview
    # at least rotates the page for you when printing (whether you like it or not, in default settings).
    #
    # So chooses sizes such that original aspect ratio is maintained, and both dimensions fit into
    # either 8.5x11 or 11x8.5, expressed with 72dpi coordinates.
    #
    # Returns an array tuple `[w, h]`
    def image_embed_dimensions(image_info)
      unless image_info.width.present? && image_info.height.present?
        # shouldn't happen, and we can do nothing.
        Rails.logger.error("#{self.class.name}: Couldn't find height and width to make PDF for #{work_id}")
        return nil
      end

      target_aspect_ratio = PAGE_WIDTH.to_f / PAGE_HEIGHT.to_f
      target_aspect_ratio_sideways = PAGE_HEIGHT.to_f / PAGE_WIDTH.to_f

      if image_info.aspect_ratio < target_aspect_ratio
        embed_height = PAGE_HEIGHT
        embed_width = (PAGE_HEIGHT.to_f * image_info.aspect_ratio).round
      elsif image_info.aspect_ratio < target_aspect_ratio_sideways
        embed_width = PAGE_WIDTH
        embed_height = (PAGE_WIDTH.to_f / image_info.aspect_ratio).round
      else
        embed_width = PAGE_HEIGHT
        embed_height = (PAGE_HEIGHT.to_f / image_info.aspect_ratio).round
      end

      return [embed_width, embed_height]
    end

    def work_presenter
      @work_presenter ||= begin
        solr_doc = SolrDocument.find(work_id)
        presenter = CurationConcerns::GenericWorkShowPresenter.new(solr_doc, Ability.new(nil))
      end
    end

    # Returns nice structs of file_set_id, height, width, aspect ratio, that we can use in our
    # construction. This works becuase we're storing width, height, and file_set_id of representative
    # image in solr, which presenters give us access to.
    def image_info_list
      @image_info_list ||= work_presenter.public_member_presenters.collect do |member|
        OpenStruct.new(
          file_set_id: member.representative_file_set_id,
          file_id: member.representative_file_id,
          checksum: member.representative_checksum,
          width: member.representative_width,
          height: member.representative_height,
          aspect_ratio: member.representative_width.to_f / member.representative_height.to_f
        )
      end
    end




    # The stack API is a mess here, and sadly our home-grown image service API is NOT
    # working out well for expanded use cases.
    def url_or_path_for_image(image_info)
      if [nil, "legacy", :legacy].include? CHF::Env.lookup(:image_server_for_thumbnails)
        CurationConcerns::DerivativePath.derivative_path_for_reference(image_info.file_set_id, "jpeg")
      elsif CHF::Env.lookup(:image_server_for_thumbnails).to_s == "dzi_s3"
        CreateDerivativesOnS3Service.s3_url(
          file_set_id: image_info.file_set_id,
          file_checksum: image_info.checksum,
          type_key: "dl_medium"
        )
      else
        raise TypeError, "Don't know how to get JPG source for CHF::Env.lookup(:image_server_for_thumbnails): `#{CHF::Env.lookup(:image_server_for_thumbnails).inspect}`"
      end
    end
  end
end
