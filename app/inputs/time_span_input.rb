class TimeSpanInput < MultiValueInput
  FORMAT_PLACEHOLDER = 'YYYY-MM-DD'

  def input(wrapper_options)
    super
  end

  protected

    LabelCol = "  <div class='col-md-3'>"
    TextCol = "  <div class='col-md-5'>"
    DropCol = "  <div class='col-md-4'>"
    LongTextCol = "  <div class='col-md-9'>"
    CheckCol = "  <div class='col-md-9 col-md-offset-3'>"

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

      if @rendered_first_element
        options[:required] = nil
      end

      options[:class] ||= []
      options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      options[:'aria-labelledby'] = label_id

      @rendered_first_element = true

      out = ''
      out << build_components(attribute_name, value, index, options)
      out << hidden_id_field(value, index) unless value.new_record?
      out
    end

    def build_components(attribute_name, value, index, options)
      out = ''

      time_span = value

      out << "<div class='row'>"

      # --- Start
      field = :start

      field_value = time_span.send(field)
      field_name = singular_input_name_for(attribute_name, index, field)

      out << LabelCol
      out << template.label_tag(field_name, field.to_s.humanize, required: false)
      out << "  </div>"

      out << TextCol
      out << @builder.text_field(field_name, options.merge(value: field_value, name: field_name, placeholder: FORMAT_PLACEHOLDER))
      out << "  </div>"

      # --- Start Qualifier
      field = :start_qualifier
      field_name = singular_input_name_for(attribute_name, index, field)
      field_value = time_span.send(field)

      out << DropCol
      out << template.select_tag(field_name, template.options_for_select(TimeSpan.start_qualifiers.map { |q| [q, q] }, field_value), {include_blank: true, label: "", class: "select form-control" })
      out << "  </div>"

      out << "</div>" # row

      out << "<div class='row'>"

      # --- Finish
      field = :finish
      field_name = singular_input_name_for(attribute_name, index, field)
      field_value = time_span.send(field)

      out << LabelCol
      out << template.label_tag(field_name, field.to_s.humanize, required: false)
      out << "  </div>"

      out << TextCol
      out << @builder.text_field(field_name, options.merge(value: field_value, name: field_name, placeholder: FORMAT_PLACEHOLDER))
      out << "  </div>"

      field = :finish_qualifier
      field_name = singular_input_name_for(attribute_name, index, field)
      field_value = time_span.send(field)

      out << DropCol
      out << template.select_tag(field_name, template.options_for_select(TimeSpan.end_qualifiers.map { |q| [q, q] }, field_value), {include_blank: true, label: "", class: "select form-control" })
      out << "  </div>"

      out << "</div>" # class=row

      field = :note
      field_value = time_span.send(field)
      field_name = singular_input_name_for(attribute_name, index, field)

      out << "<div class='row'>"
      out << LabelCol
      out << template.label_tag(field_name, field.to_s.humanize, required: false)
      out << "  </div>"

      out << LongTextCol
      out << @builder.text_field(field_name, options.merge(value: field_value, name: field_name))
      out << "  </div>"
      out << "</div>" # class=row

      out
    end

    def time_span_qualifier_options
      TimeSpan.qualifiers.map { |q| [q, q] }
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

    def destroy_name_for(attribute_name, index)
      singular_input_name_for(attribute_name, index, "_destroy")
    end

    def singular_input_name_for(attribute_name, index, field)
      "#{@builder.object_name}[#{attribute_name}_attributes][#{index}][#{field}]"
    end

    def id_for(attribute_name, index, field)
      [@builder.object_name, "#{attribute_name}_attributes", index, field].join('_'.freeze)
    end

end
