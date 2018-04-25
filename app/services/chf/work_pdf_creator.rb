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

module CHF
  class WorkPdfCreator
    # US Letter size, 612x792px at 72dpi (which is what prawn uses for it's coordinates, I think).
    # We create the pages at this size (with no margins), but embed images at higher res.
    # US letter is 2550x3300 at 300dpi -- most printers are higher than that, even budget printers are 300dpi these days.
    # no actual monitors are at 72dpi these days, even the lowest-res laptop is probably 100.
    # mobile tends to be 150 and up, up to 400 for some iphones.
    PAGE_WIDTH = 612
    PAGE_HEIGHT = 792

    attr_reader :work_id
    def initialize(work_id)
      @work_id = work_id
    end

    def write_pdf(filepath)
      make_prawn_pdf.render_file(filepath)
    end

    # you probably want {#write_pdf} instead. We intentionally write to disk
    # to not use huge RAM for our potentially huge PDFs.
    def make_prawn_pdf
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

      image_info_list.each do |image_info|
        #pdf.start_new_page(:size => [pg_w, pg_h], :layout => :portrait, :margin => 0)
        pdf.start_new_page
        #y_pos = pdf.cursor   # Record the top y value (y=0 is the bottom of the page)

        #pdf.image open(url_or_path_for_image(image_info), "rb"), :at => [0, y_pos], :fit => fit_value
        pdf.image open(url_or_path_for_image(image_info), "rb"), vposition: :center, position: :center, fit: [PAGE_WIDTH, PAGE_HEIGHT]
      end

      return pdf
    end

    protected

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
      @image_info_list ||= work_presenter.member_presenters.collect do |member|
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
          type_key: "dl_small"
        )
      else
        raise TypeError, "Don't know how to get JPG source for CHF::Env.lookup(:image_server_for_thumbnails): `#{CHF::Env.lookup(:image_server_for_thumbnails).inspect}`"
      end
    end
  end
end
