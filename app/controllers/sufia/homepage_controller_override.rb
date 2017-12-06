Sufia::HomepageController.class_eval do
  # we don't actually want our local layout, cause it adds the search bar at the top
  # which we don't want. This is messy, yeah, not sure what this is doing honestly.
  layout 'sufia'
end
