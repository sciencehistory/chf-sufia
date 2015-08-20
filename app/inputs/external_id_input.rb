class ExternalIdInput < MultiValueSelectTextWithHelpInput
  include ApplicationHelper

  # instead of using model fields, use the list of dummy fields in the form.
  #   to grab existing values in order to prepopulate the form

  def collection
    @collection ||= begin
      col = CHF::Utils::ParseFields.parse_external_ids_for_form(object.send(attribute_name))
      col << ['','']
    end
    @collection
  end

  def build_field (pair, index)
    if @rendered_first_element
      input_html_options[:required] = nil
    end
    select_field = build_select_field pair.first
    text_field = build_text_field pair
    @rendered_first_element = true
    select_field << text_field
  end

  def build_select_field(selected)
    @label_method = lambda {|l| l.last}
    @value_method = lambda {|l| "#{l.first}_external_id"}
    merged_input_options = merge_wrapper_options(input_html_options, @wrapper_options)
    input_options[:selected] = "#{selected}"
    select_field = @builder.collection_select(
      attribute_name, CHF::Utils::ParseFields.external_ids_hash, @value_method, @label_method,
      input_options, merged_input_options
    )
  end

end
