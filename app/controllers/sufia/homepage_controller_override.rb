Sufia::HomepageController.class_eval do
  # we don't actually want our local layout, cause it adds the search bar at the top
  # which we don't want. This is messy, yeah, not sure what this is doing honestly.
  layout 'sufia'

  # Override parent to:
  # * cache,
  # * force empty search for only _public_ works.
  # * For now, force to 0 rows for performance, since we aren't using any of them.
  # * Allow no-arg, since we're ignoring it anyway.
  #
  # Does require  some hard-coded assumptions about solr field names and app query param mappings,
  # including that we have a 'visibility' facet to use here.
  # Sorry, best I could come up with trying to deal with the stack.
  def search_results(user_params = {})
    @search_results ||= super(q: '', rows: 0, f: { visibility_ssi: ["open"]})
  end

  protected

  def public_works_count
    @public_works_count ||= search_results.first.total
  end
  helper_method :public_works_count
end
