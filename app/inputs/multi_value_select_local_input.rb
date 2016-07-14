# multivalue, but dropdowns instead of text fields
class MultiValueSelectLocalInput < MultiValueInput #(defined in hydra-editor)

  def build_field_options(value, index)
    options = input_html_options.dup

    options[:value] = value
    if @rendered_first_element
      options[:id] = nil
      options[:required] = nil
    else
      options[:id] ||= input_dom_id
    end
    options[:class] ||= []
    options[:class] += ["#{input_dom_id} form-control multi-select-field"]
    options[:'aria-labelledby'] = label_id
    @rendered_first_element = true

    options
  end

  # simple_form input::base creates @options, aka input_options, as well as @html_input_options
  #   input_options is all about controlling the behavior of the input itself, e.g.
  #     :as=>:multi_value_select,
  #     :include_blank=>true,
  #     :options=>
  #       ["Advertisements"...
  #   html_input_options is for class, name, etc.
  def build_field(value, index)
    # TODO: PR for initialize method to set wrapper_options = null?
    #   currently we're not using wrapper_options and parent isn't either so gonna forget about this.
    local_html_options = build_field_options(value, index)
    merged_input_options = merge_wrapper_options(local_html_options, @wrapper_options)
    #binding.pry
    # finally found this method definition; it's in rails' ActionView
    # https://github.com/rails/rails/blob/5373bf228d1273deae0ed03370ec4a63c580422b/actionview/lib/action_view/helpers/form_options_helper.rb#L201
    input_options[:selected] = "#{value}"
    @value_method = :to_s
    @label_method = :to_s
    @builder.collection_select(
      attribute_name, select_options(input_options), @value_method, @label_method,
      input_options, local_html_options
    )
  end

  def select_options(input_options)
    @select_options ||= input_options.delete(:options)
  end

  # Overriding this so that the class is correct and the javascript for multivalue will work on this.
  def input_type
    'multi_value'.freeze
  end
end
