Blacklight.onLoad(function() {
  // CHF edit: basically this entire file has now been replaced.

  // CHF edit: add FAST autocomplete to subject field
  function fast_autocomplete_opts(index) {
    var autocomplete_opts = {
      minLength: 2,
      source: function( request, response ) {
        $.getJSON( "/qa/search/assign_fast/" + index, {
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

  // CHF edit: hard-code subject to use new fast qa endpoint
  $("#generic_file_subject")
    // don't navigate away from the field on tab when selecting an item
    .bind( "keydown", function( event ) {
        if ( event.keyCode === $.ui.keyCode.TAB &&
                $( this ).data( "autocomplete" ).menu.active ) {
            event.preventDefault();
        }
    })
    .autocomplete( fast_autocomplete_opts('all'));

  $("input.generic_file_place_of_manufacture").autocomplete(fast_autocomplete_opts('geographic'));
  $("input.generic_file_place_of_interview").autocomplete(fast_autocomplete_opts('geographic'));
  $("input.generic_file_place_of_publication").autocomplete(fast_autocomplete_opts('geographic'));

  // attach an auto complete based on the field
  function setup_autocomplete(e, cloneElem) {
    var $cloneElem = $(cloneElem);
    // FIXME this code (comparing the id) depends on a bug. Each input has an id and the id is
    // duplicated when you press the plus button. This is not valid html.
    if (($cloneElem.attr("id") == 'generic_file_place_of_manufacture') || ($cloneElem.attr("id") == 'generic_file_place_of_interview') || ($cloneElem.attr("id") == 'generic_file_place_of_publication')) {
      $cloneElem.autocomplete(fast_autocomplete_opts('geographic'));
    } else if ($cloneElem.attr("id") == 'generic_file_subject') {
      // CHF edit - add FAST for subject
      $cloneElem.autocomplete(fast_autocomplete_opts('all'));
    }
  }

  // chf edit: configure text field 'name' and 'id' based on selected option from dropdown.
  function link_field_pair($select) {
    var $text = $select.next();
    var attribute = $select.val();
    var old_name = $select.attr("name");
    var old_id = $select.attr("id");
    var suffix_regex = /_([a-zA-Z]+)$/;
    var matches = suffix_regex.exec(old_id);
    var suffix = matches[1];
    $text.attr('id', old_id.replace(suffix, attribute));
    $text.attr('name', old_name.replace(suffix, attribute));
  }
  $('.double-input select').change(function() { link_field_pair($(this)) });

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

  $('.time-span.form-group').manage_time_span_fields();
  $('.multi_value.form-group').manage_fields({add: chf_add});
});
