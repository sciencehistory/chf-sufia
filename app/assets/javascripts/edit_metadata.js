// why not set up a local namespace
var chf = chf || {}
chf.autocompletes = chf.autocompletes || {
  generic_work_subject: '/authorities/search/assign_fast/all',
  generic_work_artist:          '/authorities/search/assign_fast/all',
  generic_work_author:          '/authorities/search/assign_fast/all',
  generic_work_creator_of_work: '/authorities/search/assign_fast/all',
  generic_work_contributor:     '/authorities/search/assign_fast/all',
  generic_work_engraver:     '/authorities/search/assign_fast/all',
  generic_work_interviewee:     '/authorities/search/assign_fast/all',
  generic_work_interviewer:     '/authorities/search/assign_fast/all',
  generic_work_manufacturer:    '/authorities/search/assign_fast/all',
  generic_work_photographer:    '/authorities/search/assign_fast/all',
  generic_work_printer_of_plates:     '/authorities/search/assign_fast/all',
  generic_work_publisher:       '/authorities/search/assign_fast/all',
  generic_work_language:       '/authorities/search/local/languages',
  generic_work_place_of_manufacture: '/authorities/search/assign_fast/all',
  generic_work_place_of_interview: '/authorities/search/assign_fast/all',
  generic_work_place_of_publication: '/authorities/search/assign_fast/all',
  generic_work_place_of_creation: '/authorities/search/assign_fast/all',
}


Blacklight.onLoad(function() {
  Sufia.autocomplete = function() {}
  // CHF edit: basically this entire file has now been replaced.

  // CHF edit: generalize source of autocomplete data
  function autocomplete_opts(auth_path) {
    var autocomplete_opts = {
      minLength: 2,
      source: function( request, response ) {
        $.getJSON( auth_path, {
          q: request.term
        }, response );
      },
      focus: function() {
        // prevent value inserted on focus
        return false;
      },
      complete: function(event) {
        $('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
      }
    };
    return autocomplete_opts;
  }

  function set_autocomplete($elem, authority) {
    $elem
        // don't navigate away from the field on tab when selecting an item
        .bind( "keydown", function( event ) {
            if ( event.keyCode === $.ui.keyCode.TAB &&
                    $( this ).data( "autocomplete" ).menu.active ) {
                event.preventDefault();
            }
        })
        .autocomplete( autocomplete_opts( authority ));
  }

  // loop over the autocomplete fields and attach the
  // events for autocomplete and create other array values for autocomplete
  for (var prop in chf.autocompletes) {
    set_autocomplete($("input." + prop), chf.autocompletes[prop]);
  }

  // attach an autocomplete based on the field
  // called when new fields are added to the form
  function setup_autocomplete(e, cloneElem) {
    var $cloneElem = $(cloneElem);
    // FIXME this code (comparing the id) depends on a bug. Each input has an id and the id is
    // duplicated when you press the plus button. This is not valid html.
    for (var prop in chf.autocompletes) {
      if ($cloneElem.hasClass(prop)) {
        set_autocomplete($cloneElem, chf.autocompletes[prop]);
      }
    }
  }

  // chf edit: configure text field name, id, and class based on selected option from dropdown.
  function link_field_pair($select_field) {
    var $text_field = $select_field.next();
    var attribute = $select_field.val();
    if (attribute) {
      var old_name = $select_field.attr("name");
      // since we're taking the id from the <select> field it always has the name of the form element
      var default_id = $select_field.attr("id");
      var suffix_regex = /_([a-zA-Z]+)$/;
      var matches = suffix_regex.exec(default_id);
      var suffix = matches[1];
      var new_id = default_id.replace(suffix, attribute);
      $text_field.attr('id', new_id);
      $text_field.attr('name', old_name.replace(suffix, attribute));
      swap_classes($text_field, new_id);
      setup_autocomplete(null, $text_field);
    } else { // when we're going back to a blank field
      var new_id = $select_field.attr("id");
      $text_field.attr('id', new_id);
      $text_field.attr('name', $select_field.attr("name"));
      swap_classes($text_field, new_id);
      // TODO: clear autocomplete? Doesn't seem like a huge priority..
    }
  }
  $('.double-input select').change(function() { link_field_pair($(this)) });

  function swap_classes($field, value) {
    var classList = $field.attr('class').split(/\s+/);
    $.each(classList, function(index, item) {
      // WARNING!! HARD-CODED STRING VALUE!
      if (item.lastIndexOf('generic_work_', 0) === 0) {
        $field.removeClass(item);
      }
    });
    $field.addClass(value);
  }

  // chf edit: each time a double-input field group is created, the select and text must be linked.
  function chf_add(e, cloneElem) {
    setup_autocomplete(e, cloneElem); // wrap previous callback
    // we have the text field. check its parent for .double-input. then pass select to link_field_pair
    var $par = $(cloneElem).parent();
    if ($par.hasClass('double-input')) {
      var $select = $par.children(":first");
      link_field_pair($select); // link once now to set text box
      $select.change(function() { link_field_pair($select) });
    }
  }

  Sufia.initialize();
  $('.multi_value.form-group').manage_fields({add: chf_add});
});
