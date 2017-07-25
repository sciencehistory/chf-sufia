class GenericWorkIndexer < CurationConcerns::WorkIndexer

  def generate_solr_document
    super.tap do |doc|
      %w(additional_credit inscription date_of_work).each do |field|
        entries = remove_duplicates(field)
        doc[ActiveFedora.index_field_mapper.solr_name(field, :stored_searchable)] = entries.map { |entry| entry.display_label }
      end
      unless object.physical_container.nil?
        require_dependency Rails.root.join('lib','chf','utils','parse_fields')
        doc[ActiveFedora.index_field_mapper.solr_name("physical_container", :stored_searchable)] = CHF::Utils::ParseFields.display_physical_container(object.physical_container)
      end

      makers = %w(after artist author addressee creator_of_work contributor engraver interviewee interviewer manufacturer photographer printer printer_of_plates publisher)
      maker_facet = makers.map { |field| object.send(field).to_a }.flatten.uniq
      doc[ActiveFedora.index_field_mapper.solr_name('maker_facet', :facetable)] = maker_facet

      places = %W{place_of_interview place_of_manufacture place_of_publication place_of_creation}
      place_facet = places.map { |field| object.send(field).to_a }.flatten.uniq
      doc[ActiveFedora.index_field_mapper.solr_name('place_facet', :facetable)] = place_facet

      doc[ActiveFedora.index_field_mapper.solr_name('year_facet', type: :integer)] = DateValues.new(object).expanded_years

      # rights as label, not just URI identifier
      license_service = CurationConcerns::LicenseService.new
      doc[ActiveFedora.index_field_mapper.solr_name('rights_label', :searchable)] = object.rights.collect do |id|
        # If the thing isn't found in the license service, just ignore it.
        license_service.authority.find(id).fetch('term', nil)
      end.compact

      if object.representative_id && object.representative
        # need to index these for when it's a child work on a parent's show page
        representative = ultimate_representative(object.representative)
        doc[ActiveFedora.index_field_mapper.solr_name('representative_width', type: :integer)] = representative.width.first if representative.width.present?
        doc[ActiveFedora.index_field_mapper.solr_name('representative_height', type: :integer)] = representative.height.first if representative.height.present?
        doc[ActiveFedora.index_field_mapper.solr_name('representative_original_file_id')] = representative.original_file.id if representative.original_file
      end
    end
  end

  private
    def remove_duplicates(field)
      entries = object.send(field).to_a
      entries.uniq! {|e| e.id} # can return nil
      entries
    end

    # If works representative is another work, find IT's representative,
    # recursively, until you get a terminal node, presumably fileset.
    def ultimate_representative(work)
      return work unless work.respond_to?(:representative)

      candidate = work.representative
      if candidate.respond_to?(:representative) &&
          candidate.representative_id.present? &&
          candidate.representative.present? &&
          ! candidate.reprsentative.equal?(candidate)
        ultimate_representative(candidate)
      else
        candidate
      end
    end

end
