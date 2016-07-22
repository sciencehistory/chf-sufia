class InscriptionInput < MultiValueInput

  def input(wrapper_options)
    super
  end

  protected

    LabelCol = "  <div class='col-md-3'>"
    InputCol = "  <div class='col-md-9'>"

    # Delegate this completely to the form.
    def collection
      @collection ||= Array.wrap(object[attribute_name]).reject { |value| value.to_s.strip.blank? }
    end

    def build_field(value, index)
      options = input_html_options.dup

      if value.respond_to? :rdf_label
        options[:name] = singular_input_name_for(attribute_name, index, 'hidden_label'.freeze)
        options[:id] = id_for(attribute_name, index, 'hidden_label'.freeze)

        if value.new_record?
          build_options_for_new_row(attribute_name, index, options)
        else
          build_options_for_existing_row(attribute_name, index, value, options)
        end
      end

      options[:required] = nil
      options[:class] ||= []
      options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      options[:'aria-labelledby'] = label_id

      out = ''
      out << hidden_id_field(value, index) unless value.new_record?
      out << build_components(attribute_name, value, index, options)
      out
    end

    def build_components(attribute_name, value, index, options)
      out = ''

      insc = value

      out << "<div class='row'>"

      # --- Location
      field = :location

      field_value = insc.send(field)
      field_name = singular_input_name_for(attribute_name, index, field)
      field_id = id_for(attribute_name, index, field)

      out << LabelCol
      out << template.label_tag(field_name, field.to_s.humanize, required: false)
      out << "  </div>"

      out << InputCol
      out << @builder.text_field(field_name, options.merge(value: field_value, name: field_name, id: field_id))
      out << "  </div>"

      # --- Text
      field = :text
      field_value = insc.send(field)
      field_name = singular_input_name_for(attribute_name, index, field)
      field_id = id_for(attribute_name, index, field)

      out << "<div class='row'>"
      out << LabelCol
      out << template.label_tag(field_name, field.to_s.humanize, required: false)
      out << "  </div>"

      out << InputCol
      out << @builder.text_area(field_name, options.merge(value: field_value, name: field_name, rows: 2, id: field_id))
      out << "  </div>"
      out << "</div>" # class=row

      out
    end

    def hidden_id_field(value, index)
      name = id_name_for(attribute_name, index)
      id = id_for(attribute_name, index, 'id'.freeze)
      hidden_value = value.new_record? ? '' : value.id
      @builder.hidden_field(attribute_name, name: name, id: id, value: hidden_value, data: { id: 'remote' })
    end

    def build_options_for_new_row(attribute_name, index, options)
      options[:value] = ''
    end

    def build_options_for_existing_row(attribute_name, index, value, options)
      options[:value] = value.rdf_label.first || "Unable to fetch label for #{value.id}"
    end

    def name_for(attribute_name, index, field)
      "#{@builder.object_name}[#{attribute_name}_attributes][#{index}][#{field}][]"
    end

    def id_name_for(attribute_name, index)
      singular_input_name_for(attribute_name, index, "id")
    end

    def singular_input_name_for(attribute_name, index, field)
      "#{@builder.object_name}[#{attribute_name}_attributes][#{index}][#{field}]"
    end

    def id_for(attribute_name, index, field)
      [@builder.object_name, "#{attribute_name}_attributes", index, field].join('_'.freeze)
    end
end
