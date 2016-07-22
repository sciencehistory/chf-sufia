class IdentifierAttributeRenderer < CurationConcerns::Renderers::AttributeRenderer

  # turn something like 'object-2008.043.002'
  # into 'Object ID: 2008.043.002'
  def attribute_value_to_html(value)
    id_pair = CHF::Utils::ParseFields.parse_external_id(value)
    "#{CHF::Utils::ParseFields.external_ids_hash[id_pair[0]]}: #{id_pair[1]}"
  end

end
