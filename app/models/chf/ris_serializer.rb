module CHF
  # https://github.com/aurimasv/translators/wiki/RIS-Tag-Map-(narrow)
  class RisSerializer < CHF::RisSerializerBase

    # Limited ability to map to RIS types -- 'manuscript' type seems to get
    # the best functionality for archival fields in most software, so we default to
    # that and use that in many places maybe we COULD have something more specific.
    self.get_type = lambda do |item, serializer|
      if item.genre_string.include?('Manuscripts')
        return "MANSCPT"
      elsif (item.genre_string & ['Personal correspondence', 'Business correspondence']).present?
        return "PCOMM"
      elsif  item.division == "Archives"
        # if it's not PCOMM, insist on MANSCPT for archival content
        return "MANSCPT"
      elsif (item.genre_string & %w{Paintings}).present?
        return "ART"
      elsif (item.genre_string & ['Rare books', 'Sample books']).present?
        return "BOOK"
      elsif item.genre_string.include?('Slides')
        return "SLIDE"
      elsif item.genre_string.include?('Documents') && item.title.any? { |v| v=~ /report/i }
        return "RPRT"
      elsif item.genre_string.include?('Encyclopedias and dictionaries')
        return "ENCYC"
      else
        return "MANSCPT"
      end
    end

    serialize :db do
      "Science History Institute Digital Collections"
    end
    serialize :dp do
      "Science History Institute"
    end

    # zotero 'extra'. endnote?
    serialize :m2 do |item|
      "Courtesy of Science History Institute." +
        # rights statement
        if item.rights.present?
          "  Rights: " + item.rights.collect do |id|
            CurationConcerns::LicenseService.new.label(id)
          end.join(", ") + (item.rights_holder.present? ? ", #{item.rights_holder}" : "")
        else
          ""
        end
    end
    #serialize :n1 # zotero notes

    serialize :ti, property: :title, predicate: ::RDF::Vocab::DC.title
    serialize :id, property: :id
    serialize :au, property: (Rails.application.config.makers - [:publisher, :printer, :printer_of_plates, :addressee]), predicate: [::RDF::Vocab::MARCRelators.aut, ::RDF::Vocab::DC.creator, ::RDF::Vocab::DC11.creator]
    serialize :pb, property: [:publisher, :printer, :printer_of_plates]
    serialize :a2, property: :addressee

    # date in RIS format
    serialize :da do |item|
      if item.date_of_work.present?
        date = item.date_of_work.first
        if date.start
          parts = date.start.scan(/\d+/)
          RisSerializerBase.ris_date(year: parts.first, month: parts.second, day: parts.third, extra: date.note)
        end
      end
    end

    serialize :yr do |item|
      item.date_of_work.try(:first).try(:start) =~ /\A(\d\d\d\d)/
      $1
    end

    serialize :ab, property: :description, predicate: [::RDF::Vocab::DC.description, ::RDF::Vocab::DC11.description], transform: proc { |v| ActionView::Base.full_sanitizer.sanitize(v) }

    serialize :cy, property: Rails.application.config.places

    serialize :kw, property: :subject, predicate: [::RDF::Vocab::DC.subject, ::RDF::Vocab::DC11.subject]
    serialize :la, property: :language, predicate: [::RDF::Vocab::DC.language, ::RDF::Vocab::DC11.language]

    serialize :m3 do |item|
      (item.genre_string || []).join(", ")
    end

    archival_location = proc do |item|
      if item.division == "Archives"
        parts = []

        parts << item.in_collections.first.title.first if item.in_collections.present?
        parts.concat item.series_arrangement.to_a if item.series_arrangement.present?
        parts = [parts.join("; ")] if parts.present?
        parts << CHF::Utils::ParseFields.display_physical_container(item.physical_container) if item.physical_container.present?

        parts.collect(&:presence).compact.join(': ')
      end
    end

    # archival location is according to wikipedia "AV". Endnote uses "VL" (volume) for this though.
    # And Zotero uses "AN" (accession number)!
    serialize :av, &archival_location
    serialize :vl, &archival_location
    serialize :an, &archival_location

    serialize :ur do |item|
      "https://digital.sciencehistory.org/works/#{item.id}"
    end
  end
end
