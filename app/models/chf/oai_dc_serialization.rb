module CHF
  class OaiDcSerialization
    # all of em from https://drive.google.com/file/d/1fJEWhnYy5Ch7_ef_-V48-FAViA72OieG/view
    # why not, be complete in case we need em.
    NAMESPACES = {
      dpla: "http://dp.la/about/map/",
      cnt: "http://www.w3.org/2011/content#",
      dc: "http://purl.org/dc/elements/1.1/",
      dcterms: "http://purl.org/dc/terms/",
      dcmitype: "http://purl.org/dc/dcmitype/",
      edm: "http://www.europeana.eu/schemas/edm/",
      gn: "http://www.geonames.org/ontology#",
      oa: "http://www.w3.org/ns/oa#",
      ore: "http://www.openarchives.org/ore/terms/",
      rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      rdfs: "http://www.w3.org/2000/01/rdf-schema#",
      skos: "http://www.w3.org/2004/02/skos/core#",
      svcs: "http://rdfs.org/sioc/services",
      wgs84: "http://www.w3.org/2003/01/geo/wgs84_pos#",
      oai_dc: "http://www.openarchives.org/OAI/2.0/oai_dc/"
    }

    # A "curation_concerns" style presenter, with `def initialize(solr_document, current_ability, request = nil)`
    class_attribute :presenter_class_name
    self.presenter_class_name = "CurationConcerns::GenericWorkShowPresenter"

    attr_reader :solr_document

    # @param solr_document [SolrDocument] represneting a GenericWork
    def initialize(solr_document)
      @solr_document = solr_document
    end

    def work_presenter
      @work_presenter ||= presenter_class_name.constantize.new(solr_document, Ability.new(nil))
    end

    # a string, which does not have an XML decleration or DTD
    def to_oai_dc
      save_options = Nokogiri::XML::Node::SaveOptions::FORMAT + Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
      as_oai_dc_builder.to_xml(save_with: save_options)
    end

    # A Nokogiri doc
    def as_oai_dc_builder
      builder = Nokogiri::XML::Builder.new do |xml|
        # have to use a hack for namespaced root element before we've provided the namespaces.
        xml.send("oai_dc:dc", xmlns_attribs) do
          xml["dc"].identifier in_our_app_url

          xml["dc"].title work_presenter.title.first

          xml["dc"].rights work_presenter.rights_url
          dc_creators.each do |creator|
            xml["dc"].creator creator
          end

          # DATE to do, need "ISO 8601 (W3CDTF) format (YYYY-MM-DD) with optional EDTF"

          xml["dc"].description work_presenter.plain_description

          work_presenter.content_types.each do |ctype|
            xml["dc"].format ctype
          end

          # Ideally should be ISO 692-2 according to PA Digital, but we don't have it, I think this will do.
          xml["dc"].language work_presenter.language.join(";")

          (work_presenter.manufacturer || []).each do |publisher|
            xml["dc"].publisher publisher
          end

          if work_presenter.rights_holder
            xml["dcterms"].rightsholder work_presenter.rights_holder.join(", ")
          end

          # Could do: dc:source archival location. A pain cause it requires collection, and
          # PA Digital says they don't currently pass it on to DPLA anyway, so we'll skip for now.
          # See CitableAttributes#archive_location for how we do it there.

          (work_presenter.subject || []).each do |subject|
            xml["dc"].subject subject
          end

          xml["dc"].type dc_type

          xml["dc"].send(:"identifier.thumbnail", thumb_url)

          ########################
          #
          # Some that are not in PA Digital Guide, but are in DPLA Metadata Application Profile, if I
          # understand it. Might as well throw them in. Some duplicate other statements expressed with
          # other terms agove.

          xml["dpla"].originalRecord in_our_app_url
          xml["edm"].preview thumb_url
          xml["edm"].rights work_presenter.rights_url

          Array(work_presenter.genre_string).each do |genre|
            xml["edm"].hasType genre.downcase
          end

          # "The URL of a suitable source object in the best resolution available on the website of the Data
          # "Provider from which edm:preview could be generated for use in available portal."
          #
          # Sorry to go right to Rails routes, kind of poor encapsulation, but it's what we've got
          # for now.
          if work_presenter.representative_file_id
            xml["edm"].object routes.download_url(work_presenter.representative_file_set_id)
          end
        end
      end
    end

    protected

    def routes
      @routes ||= Class.new do
        # somewhere said this is a better way to use global routes to avoid memory leak in rails
        include Rails.application.routes.url_helpers
      end.new
    end

    def in_our_app_url
      "https://digital.sciencehistory.org/works/#{work_presenter.id}"
    end

    # "Repeatable: no"
    # "Recommend use of local controlled vocabulary and/ or DCMI Type Vocabulary."
    # "Recommended best practice is to assign the type Text to images of textual materials."
    def dc_type
      return @dc_type if defined?(@dc_type)

      # we have more than one, can only have one.
      @dc_type ||= if Array(work_presenter.resource_type).include?("Text")
        "Text"
      else
        Array(work_presenter.resource_type).first
      end
    end

    def dc_creators
      # We'll use the same subset of all our 'maker' fields we use in our citations in CitableAttributes
      @dc_creators ||= begin
        arr =  work_presenter.creator_of_work || []
        arr += work_presenter.author || []
        arr += work_presenter.artist || []
        arr += work_presenter.photographer || []
        arr += work_presenter.engraver || []
        arr
      end
    end

    # using our custom in-house object that can give us thumbnail URLs, but not with
    # quite a convenient API for this, oh well. We want "medium" _download_ size
    def thumb_url
      @thumb_url ||= begin
        service = ImageServiceHelper.image_url_service_class(CHF::Env.lookup(:image_server_downloads)).new(
          file_set_id: work_presenter.representative_file_set_id,
          file_id: work_presenter.representative_file_id,
          checksum: work_presenter.representative_checksum
        )
        download_options = service.download_options
        (download_options.find { |h| h[:option_key] == "medium "} || download_options.first).try { |h| h[:url] }
      end
    end

    def xmlns_attribs
      NAMESPACES.collect do |key, value|
        ["xmlns:#{key.to_s}", value]
      end.to_h
    end

  end
end
