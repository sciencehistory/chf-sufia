// Sufia/hyrax JS for sending event tracking to Google Analytics is a bit inflexible.
// https://github.com/samvera/hyrax/blob/1e504c200fd9c39120f514ac33cd42cd843de9fa/app/assets/javascripts/hyrax/ga_events.js
//
// We add our own more flexible.
//
// https://developers.google.com/analytics/devguides/collection/gajs/eventTrackerGuide

$(document).on('click', '*[data-analytics-category]', function(e) {
  _gaq.push(['_trackEvent',
             e.target.getAttribute("data-analytics-category"),
             e.target.getAttribute("data-analytics-action"),
             e.target.getAttribute("data-analytics-label"),
             e.target.getAttribute("data-analytics-value")
            ]);
});


// Track the "Back to search results" link specially, because we don't
// control it's data attributes from sufia
$(document).on("click", "ul.breadcrumb li a", function(e) {
  if (e.target && e.target.text == "Back to search results") {
    _gaq.push(['_trackEvent',
               "interesting_clicks",
               "back_to_search_results"]);
  }
});
