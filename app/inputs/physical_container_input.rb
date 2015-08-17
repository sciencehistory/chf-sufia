class PhysicalContainerInput < SimpleForm::Inputs::TextInput
  include ApplicationHelper
  include WithHelpIcon

  LabelCol = "  <div class='col-md-3'>"
  TextCol = "  <div class='col-md-9'>"

  #Example html:
  #<input class="string optional form-control" type="text" value="" name="generic_file[provenance]" id="generic_file_provenance">

  def input(wrapper_options = nil)
    @merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    @vals = CHF::Utils::ParseFields.parse_physical_container(object.send(attribute_name))
    out = ''
    out << "<div class='listing'>"
    CHF::Utils::ParseFields.physical_container_fields.values.each do |field|
      out << build_field(field)
    end
    out << "</div>"
  end

  def build_field(field)
    #options = input_html_options.dup
    out = ''
    out << '<div class=row>'
    out << LabelCol

    out << template.label_tag(id_for(field), field.to_s.humanize, required: false)
    out << "</div>"
    out << TextCol
    out << @builder.text_field(field, @merged_input_options.merge(name: name_for(field), value: @vals[field[0]]))
    out << "</div>"
    out << "</div>"
    out
  end

  private
    def id_for(field)
      [@builder.object_name, field].join('_'.freeze)
    end

    def name_for(field)
      "#{object_name}[#{field}]"
    end
end
