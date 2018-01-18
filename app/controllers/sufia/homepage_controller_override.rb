Sufia::HomepageController.class_eval do
  # we don't actually want our local layout, cause it adds the search bar at the top
  # which we don't want. This is messy, yeah, not sure what this is doing honestly.
  layout 'sufia'


  # The default `Sufia::HomepageSearchBuilder` limits to just works. We actually
  # want everything that shows up in a normal search, but to limit to only public things,
  # to support our live count of items and have it match search results for public users.
  #
  # We override to a custom search builder to do that.
  def search_builder_class
    SearchBuilder::HomePage
  end

  protected

  def public_works_count
    @public_works_count ||= search_results({}).first.total
  end
  helper_method :public_works_count
end
