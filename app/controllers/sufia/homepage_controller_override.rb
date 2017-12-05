Sufia::HomepageController.class_eval do
  # We want our custom layout here, not entirely sure why we need to repeat it.
  # We want to disable search bar though, since we show it otherwise, we do that
  # with a content_for suppress_controls in template.
  layout 'chf'
end
