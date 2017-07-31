module CHF
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

        representative = ultimate_representative(object)
        if representative
          # need to index these for when it's a child work on a parent's show page
          # Note corresponding code in GenericWork#update_index makes sure works using
          # this work as a representative also get updated.
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
      # Return nil if there is no terminal representative.
      def ultimate_representative(work)
        return nil unless work.representative_id && work.representative

        candidate = work.representative
        return nil if candidate.equal?(work) # recursive self-pointing representative, bah

        if candidate.respond_to?(:representative)
          ultimate_representative(candidate)
        else
          candidate
        end
      end
  end
end
