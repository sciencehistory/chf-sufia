class GenericWorkIndexer < CurationConcerns::WorkIndexer

  def generate_solr_document
    super.tap do |doc|
      %w(additional_credit inscription date_of_work).each do |field|
        entries = remove_duplicates(field)
        doc[ActiveFedora.index_field_mapper.solr_name(field, type: :string)] = entries.map { |entry| entry.display_label }
      end
      unless object.physical_container.nil?
        require_dependency Rails.root.join('lib','chf','utils','parse_fields')
        doc[ActiveFedora.index_field_mapper.solr_name("physical_container", type: :string)] = CHF::Utils::ParseFields.display_physical_container(object.physical_container)
      end
    end
  end

  private
    def remove_duplicates(field)
      entries = object.send(field).to_a
      entries.uniq! {|e| e.id} # can return nil
      entries
    end
end
