class AdditionalCreditInput < MultiValueWithHelpInput

  def input(wrapper_options)
    super
  end

  protected

    DropCol = "  <div class='col-md-6'>"

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

      ac = value

      out << "<div class='row'>"

      # --- Role
      field = :role

      field_value = ac.send(field)
      field_name = singular_input_name_for(attribute_name, index, field)

      out << DropCol
      out << template.select_tag(field_name, template.options_for_select(Credit.role_options.map { |k, v| [v, k] }, field_value), {include_blank: true, label: "", class: "select form-control" })
      out << "  </div>"

      # --- Name
      field = :name
      field_value = ac.send(field)
      field_name = singular_input_name_for(attribute_name, index, field)

      out << DropCol
      out << template.select_tag(field_name, template.options_for_select(Credit.name_options.map { |v| [v, v] }, field_value), {include_blank: true, label: "", class: "select form-control" })
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
