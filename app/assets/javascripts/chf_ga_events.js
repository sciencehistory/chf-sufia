// Sufia/hyrax JS for sending event tracking to Google Analytics is a bit inflexible.
// https://github.com/samvera/hyrax/blob/1e504c200fd9c39120f514ac33cd42cd843de9fa/app/assets/javascripts/hyrax/ga_events.js
//
// We add our own more flexible.
//
// https://developers.google.com/analytics/devguides/collection/gajs/eventTrackerGuide

$(document).on('click', '*[data-analytics-event]', function(e) {
  _gaq.push(['_trackEvent',
             e.target.getAttribute("data-analytics-event"),
             e.target.getAttribute("data-analytics-label"),
             e.target.getAttribute("data-analytics-value")
            ]);
});
