# Creates a repeatable (i.e. with add/remove buttons) unit of
#   select box, text field form elements. Use case:
#   a set of fields defined on the model are related but not nested in another class.
#   e.g. a bunch of mark relators to be used as creator/contributor values.
#   make an attr_accessor on the form itself to use as a dummy / wrapper for
#     the actual model fields you want to populate.
#   specify the list of fields as the 'options'
#   for an example see app/views/records/edit_fields/_maker.html.erb
# TODO: see curation concerns 'multivalueselectinput'
class MultiValueSelectTextInput < MultiValueInput #(defined in hydra-editor)

  # Overriding this so that the class is correct and the javascript for multivalue will work on this.
  # (gives 'multi_value' class)
  def input_type
    'multi_value'.freeze
  end

  # call to super hits MultiValueInput (defined in hydra-editor)
  def input(wrapper_options = nil)
    # save this since we actually use it later; parents did not
    @wrapper_options = wrapper_options
    super
  end

  protected
    # add another class here to use for
    # linking the two fields in javascript, adjusting field width
    def inner_wrapper
        <<-HTML
          <li class="field-wrapper double-input">
            #{yield}
          </li>
        HTML
    end

  private

    # use the options (which should be a list of model fields (symbols))
    #   to grab existing values in order to prepopulate the form
    def collection
      @collection ||= begin
        col = []
        options[:options].each do |attr|
          attr_array = Array.wrap(object[attr]).reject do |value|
            value.to_s.strip.blank?
          end
          attr_array.each do |entry|
            col << [attr, entry]
          end
        end
        col << ['','']
        # Sub in the below when I re-arrange the add / remove buttons
        # and get rid of the always-present empty field
        #if col.empty? then col << ['', ''] end
      end
      @collection
    end

    def build_field (pair, index)
      select_field = build_select_field pair.first
      text_field = build_text_field pair
      select_field << text_field
    end

    # reference code:
    #   https://github.com/plataformatec/simple_form/blob/master/lib/simple_form/inputs/collection_select_input.rb
    def build_select_field(selected)
      # for some reason these are only set correctly the first time through
      unless defined?(@label_method)
        @label_method, @value_method = detect_collection_methods
      end
      merged_input_options = merge_wrapper_options(input_html_options, @wrapper_options)
      input_options[:selected] = selected
      # I found this arg list difficult to parse; all are received from the erb
      #   options[:options] is the options list passed in from erb file
      #     (should be list of actual fields to populate)
      #   value_method is a function that translates each option into a value
      #     (you probably want :to_s -- :first is the default)
      #   label_method is a function that translates each option into a label
      #     (you probably want :to_s -- :second is the default)
      #     (in future, i may try to use i18n on the resulting string)
      # normal use of this field would pass the actual collection where we pass
      #   options
      select_field = @builder.collection_select(
        attribute_name, options[:options], @value_method, @label_method,
        input_options, merged_input_options
      )
    end

    def build_text_field(pair)
      key, value = pair
      key = key.present? ? key : attribute_name
      options = input_html_options.dup
      options[:name] = "#{object_name}[#{key.to_s}][]"
      options[:value] = value
      options[:id] ||= input_dom_id(key)
      options[:class] ||= []
      options[:class] += ["#{input_dom_id key} form-control multi-text-field"]
      @builder.text_field(key, options)
    end

    # id should be based on the selected field, not the dummy/wrapper field
    def input_dom_id(key)
      "#{object_name}_#{key.to_s}"
    end
end
