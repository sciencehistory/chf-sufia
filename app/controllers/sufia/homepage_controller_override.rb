Sufia::HomepageController.class_eval do
  # we don't actually want our local layout, cause it adds the search bar at the top
  # which we don't want. This is messy, yeah, not sure what this is doing honestly.
  layout 'sufia'
  before_filter :recent_items


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

  def recent_items
    how_many_works_to_show = 5
    how_often_to_change = 60 * 10 # ten minutes in seconds
    how_many_works_in_bag = 15

    #First, put a bunch of eligible works into a bag.
    # Note that the call to SOLR is memoized.
    conditions =  {'read_access_group_ssim'=>'public'}
    sort_by = ["system_modified_dtsi desc"]
    opts = {:rows=>how_many_works_in_bag, :sort=>sort_by}
    @works_to_pick_from ||= GenericWork.search_with_conditions( conditions, opts)

    # Now, pick a few of these out of the bag at random to show.
    # Reshuffle the bag every now and then.
    srand Time.now.to_i/how_often_to_change
    @works_to_pick_from.sort_by{rand}[0...how_many_works_to_show]
  end
  helper_method :recent_items

  def featured_collection_image_link(work_id, title)
    begin
      @solr_doc ||= SolrDocument.find(work_id)
    rescue
      return view_context.link_to("Image not in this repository", "#")
    end
    view_context.link_to(@solr_doc.title.first, curation_concerns_generic_work_path(solr_doc.id))
  end
  helper_method :featured_collection_image_link


end
