// why not set up a local namespace
var chf = chf || {}
chf.autocompletes = chf.autocompletes || {
  generic_file_subject: 'assign_fast/all',
  generic_file_place_of_manufacture: 'assign_fast/geographic',
  generic_file_place_of_interview: 'assign_fast/geographic',
  generic_file_place_of_publication: 'assign_fast/geographic',
  generic_file_artist:          'assign_fast/all',
  generic_file_author:          'assign_fast/all',
  generic_file_creator_of_work: 'assign_fast/all',
  generic_file_contributor:     'assign_fast/all',
  generic_file_interviewee:     'assign_fast/all',
  generic_file_interviewer:     'assign_fast/all',
  generic_file_manufacturer:    'assign_fast/all',
  generic_file_photographer:    'assign_fast/all',
  generic_file_publisher:       'assign_fast/all',
  generic_file_language:       'local/languages',
}

Blacklight.onLoad(function() {
  // CHF edit: basically this entire file has now been replaced.

  // CHF edit: use qa as source of autocomplete data
  function qa_autocomplete_opts(auth_path) {
    var autocomplete_opts = {
      minLength: 2,
      source: function( request, response ) {
        $.getJSON( "/qa/search/" + auth_path, {
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

  // loop over the autocomplete fields and attach the
  // events for autocomplete and create other array values for autocomplete
  for (var prop in chf.autocompletes) {
    set_autocomplete($("input." + prop), chf.autocompletes[prop]);
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
        .autocomplete( qa_autocomplete_opts( authority ));
  }

  // attach an auto complete based on the field
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

  // chf edit: configure text field 'name' and 'id' based on selected option from dropdown.
  function link_field_pair($select) {
    var $text = $select.next();
    var attribute = $select.val();
    var old_name = $select.attr("name");
    // since we're taking the id from the <select> field it always has the name of the form element
    //   (this means it will be the same as the 'old' class)
    var old_id = $select.attr("id");
    var suffix_regex = /_([a-zA-Z]+)$/;
    var matches = suffix_regex.exec(old_id);
    var suffix = matches[1];
    var new_id = old_id.replace(suffix, attribute);
    $text.attr('id', new_id);
    $text.attr('name', old_name.replace(suffix, attribute));
    $text.removeClass(old_id).addClass(new_id);
    setup_autocomplete(null, $text);
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

  $('.multi_value.form-group').manage_fields({add: chf_add});
});
