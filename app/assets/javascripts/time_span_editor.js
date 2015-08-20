//TODO: are these lines needed?
//= require hydra-editor/hydra-editor
//= require handlebars-v3.0.3.js

// We use HydraEditor.FieldManager as a basis for this modification,
//   specific to timespan form fields.

var source = "<li class=\"field-wrapper input-group input-append\">" +
  "<div class=\"row\">  <div class=\"col-md-3\"><label for=\"generic_file_{{name}}_attributes_{{index}}_start\">Start</label>  </div>" +
    "<div class=\"col-md-5\"><input class=\"string multi_value optional form-control generic_file_{{name}} form-control multi-text-field\" name=\"generic_file[{{name}}_attributes][{{index}}][start]\" id=\"generic_file_{{name}}_attributes_{{index}}_hidden_label\" aria-labelledby=\"generic_file_{{name}}_label\" placeholder=\"YYYY-MM-DD\" type=\"text\">  </div>" +
    "<div class=\"col-md-4\"><select name=\"generic_file[{{name}}_attributes][{{index}}][start_qualifier]\" id=\"generic_file_{{name}}_attributes_{{index}}_start_qualifier\" label=\"\" class=\"select form-control\"><option value=\"\"></option><option value=\"before\">before</option> <option value=\"after\">after</option> <option value=\"circa\">circa</option> <option value=\"decade\">decade</option> <option value=\"undated\">undated</option></select>  </div></div>" +
  "<div class=\"row\">  <div class=\"col-md-3\"><label for=\"generic_file_{{name}}_attributes_{{index}}_finish\">Finish</label>  </div>" +
    "<div class=\"col-md-5\"><input class=\"string multi_value optional form-control generic_file_{{name}} form-control multi-text-field\" name=\"generic_file[{{name}}_attributes][{{index}}][finish]\" id=\"generic_file_{{name}}_attributes_{{index}}_hidden_label\" aria-labelledby=\"generic_file_{{name}}_label\" placeholder=\"YYYY-MM-DD\" type=\"text\">  </div>" +
    "<div class=\"col-md-4\"><select name=\"generic_file[{{name}}_attributes][{{index}}][finish_qualifier]\" id=\"generic_file_{{name}}_attributes_{{index}}_finish_qualifier\" label=\"\" class=\"select form-control\"><option value=\"\"></option><option value=\"before\">before</option> <option value=\"circa\">circa</option></select>  </div></div>" +
  "<div class=\"row\">  <div class=\"col-md-3\"><label for=\"generic_file_{{name}}_attributes_{{index}}_note\">Note</label>  </div>  <div class=\"col-md-9\"><input class=\"string multi_value optional form-control generic_file_{{name}} form-control multi-text-field\" name=\"generic_file[{{name}}_attributes][{{index}}][note]\" id=\"generic_file_{{name}}_attributes_{{index}}_hidden_label\" aria-labelledby=\"generic_file_{{name}}_label\" type=\"text\">  </div></div>" +
    "<div class=\"row\"><div class=\"col-md-offset-3 col-md-9\">" +
  "<input name=\"generic_file[{{name}}_attributes][{{index}}][_destroy]\" type=\"hidden\" value=\"0\"><input name=\"generic_file[{{name}}_attributes][{{index}}][_destroy]\" id=\"generic_file_{{name}}_attributes_{{index}}__destroy\" value=\"1\" data-destroy=\"true\" type=\"checkbox\"><label class=\"remove_time_span\" for=\"generic_file_{{name}}_attributes_{{index}}__destroy\">Remove</label>  </div></div>" +
  "<span class=\"input-group-btn field-controls\"><button class=\"btn btn-success add\"><i class=\"icon-white glyphicon-plus\"></i><span>Add</span></button></span></li>";
//  "<input name=\"image[{{name}}_attributes][{{index}}][_destroy]\" id=\"image_{{name}}_attributes_{{index}}__destroy\" value=\"\" data-destroy=\"true\" type=\"hidden\"><span class=\"input-group-btn field-controls\"><button class=\"btn btn-success add\"><i class=\"icon-white glyphicon-plus\"></i><span>Add</span></button></span></li>";

var template = Handlebars.compile(source);

function TimeSpanFieldManager(element, options) {
    HydraEditor.FieldManager.call(this, element, options); // call super constructor.
}

TimeSpanFieldManager.prototype = Object.create(HydraEditor.FieldManager.prototype,
    {
        createNewField: { value: function($activeField) {
            var fieldName = $activeField.find('input').data('name');
            $newField = this.newFieldTemplate(fieldName);
            this.addBehaviorsToInput($newField)
            return $newField
        }},

        /* This gives the index for the editor */
        maxIndex: {
            value: function() {
                return $(this.fieldWrapperClass, this.element).size();
        }},

        // Overridden because the input is not a direct child of activeField
        inputIsEmpty: {
            value: function(activeField) {
              return activeField.find('input.multi-text-field').val() === '';

        }},

        newFieldTemplate: { value: function(fieldName) {
            var index = this.maxIndex();
            return $(template({ "name": fieldName, "index": index }));
        }},

        addBehaviorsToInput: { value: function($newField) {
            $newInput = $('input.multi-text-field', $newField);
            $newInput.focus();
            this.element.trigger("managed_field:add", $newInput);
        }},

        // TODO: broken..
        // Instead of removing the line, we override this method to add a
        // '_destroy' hidden parameter
        removeFromList: { value: function( event ) {
            event.preventDefault();
            var field = $(event.target).parents(this.fieldWrapperClass);
            field.find('[data-destroy]').val('true')
            field.hide();
            this.element.trigger("managed_field:remove", field);
      }}

    }
);
TimeSpanFieldManager.prototype.constructor = TimeSpanFieldManager;

$.fn.manage_time_span_fields = function(option) {
    return this.each(function() {
        var $this = $(this);
        var data  = $this.data('manage_fields');
        var options = $.extend({}, HydraEditor.FieldManager.DEFAULTS, $this.data(), typeof option == 'object' && option);
        if (!data) $this.data('manage_fields', (data = new TimeSpanFieldManager(this, options)));
    })
}
