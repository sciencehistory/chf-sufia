// why not set up a local namespace
var chf = chf || {}
chf.autocompletes = chf.autocompletes || {
  generic_file_subject: '/qa/search/assign_fast/all',
  generic_file_artist:          '/qa/search/assign_fast/all',
  generic_file_author:          '/qa/search/assign_fast/all',
  generic_file_creator_of_work: '/qa/search/assign_fast/all',
  generic_file_contributor:     '/qa/search/assign_fast/all',
  generic_file_interviewee:     '/qa/search/assign_fast/all',
  generic_file_interviewer:     '/qa/search/assign_fast/all',
  generic_file_manufacturer:    '/qa/search/assign_fast/all',
  generic_file_photographer:    '/qa/search/assign_fast/all',
  generic_file_publisher:       '/qa/search/assign_fast/all',
  generic_file_language:       '/qa/search/local/languages',
  generic_file_place_of_manufacture: '/qa/search/assign_fast/all',
  generic_file_place_of_interview: '/qa/search/assign_fast/all',
  generic_file_place_of_publication: '/qa/search/assign_fast/all',
  generic_file_place_of_creation: '/qa/search/assign_fast/all',
}

Blacklight.onLoad(function() {
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
      console.log(item);
      // WARNING!! HARD-CODED STRING VALUE!
      if (item.lastIndexOf('generic_file_', 0) === 0) {
        console.log('yes');
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
      $select.change(function() { link_field_pair($select) });
    }
  }

  $('.multi_value.form-group').manage_fields({add: chf_add});
});
