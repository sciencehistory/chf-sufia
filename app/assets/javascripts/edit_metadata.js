Blacklight.onLoad(function() {
  // TODO: all this autocomplete code should be refactored into its own 
  //   file as a plugin.
  function get_autocomplete_opts(field) {
    var autocomplete_opts = {
      minLength: 2,
      source: function( request, response ) {
        $.getJSON( "/authorities/generic_files/" + field, {
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

    // there are two levels of vocabulary auto complete.
    // currently we have this externally hosted vocabulary
    // for geonames.  I'm not going to make these any easier
    // to implement for an external url (it's all hard coded)
    // because I'm guessing we'll get away from the hard coding
  var cities_autocomplete_opts = {
    source: function( request, response ) {
      $.ajax( {
        url: "http://ws.geonames.org/searchJSON",
        dataType: "jsonp",
        data: {
          featureClass: "P",
          style: "full",
          maxRows: 12,
          name_startsWith: request.term
        },
        success: function( data ) {        response( $.map( data.geonames, function( item ) {
            return {
              label: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName,
              value: item.name + (item.adminName1 ? ", " + item.adminName1 : "") + ", " + item.countryName
            };
          }));
        },
      });
    },
    minLength: 2
  };
  $("input.generic_file_based_near").autocomplete(get_autocomplete_opts("location"));

//  var autocomplete_vocab = new Object();
//
//  autocomplete_vocab.url_var = ['language'];   // the url variable to pass to determine the vocab to attach to
//  autocomplete_vocab.field_name = new Array(); // the form name to attach the event for autocomplete
//
//  // loop over the autocomplete fields and attach the
//  // events for autocomplete and create other array values for autocomplete
//  for (var i=0; i < autocomplete_vocab.url_var.length; i++) {
//    autocomplete_vocab.field_name.push('generic_file_' + autocomplete_vocab.url_var[i]);
//    // autocompletes
//    $("input." + autocomplete_vocab.field_name[i])
//        // don't navigate away from the field on tab when selecting an item
//        .bind( "keydown", function( event ) {
//            if ( event.keyCode === $.ui.keyCode.TAB &&
//                    $( this ).data( "autocomplete" ).menu.active ) {
//                event.preventDefault();
//            }
//        })
//        .autocomplete( get_autocomplete_opts(autocomplete_vocab.url_var[i]) );
//  }

  // CHF edit: add FAST autocomplete to subject field
  function subject_autocomplete_opts() {
    var autocomplete_opts = {
      minLength: 2,
      source: function( request, response ) {
        $.getJSON( "/qa/search/assign_fast/all", {
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
    .autocomplete( subject_autocomplete_opts());

  // attach an auto complete based on the field
  function setup_autocomplete(e, cloneElem) {
    var $cloneElem = $(cloneElem);
    // FIXME this code (comparing the id) depends on a bug. Each input has an id and the id is
    // duplicated when you press the plus button. This is not valid html.
    if ($cloneElem.attr("id") == 'generic_file_based_near') {
      $cloneElem.autocomplete(cities_autocomplete_opts);
    } else if ($cloneElem.attr("id") == 'generic_file_subject') {
      // CHF edit - add FAST for subject
      $cloneElem.autocomplete(subject_autocomplete_opts());
//    } else if ( (index = $.inArray($cloneElem.attr("id"), autocomplete_vocab.field_name)) != -1 ) {
//      $cloneElem.autocomplete(get_autocomplete_opts(autocomplete_vocab.url_var[index]));
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
