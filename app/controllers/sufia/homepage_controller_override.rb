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

  def recent_items
    how_many_works_to_show = 6
    how_often_to_change = 60 * 10 # ten minutes in seconds

    # @@arbitrary_number is a slowly incrementing integer that changes at most every
    # how_often_to_change minutes. When it does change, we a new bag of recent works
    # from SOLR and reshuffle the bag even if there haven't been any new works added.
    new_arbitrary_number = Time.now.to_i / how_often_to_change
    if (!defined? @@arbitrary_number) || (@@arbitrary_number != new_arbitrary_number)
      @@arbitrary_number = new_arbitrary_number
      @@bag_of_recent_items = nil # thus forcing a new call to SOLR.
    end

    #First, put a bunch of eligible works into a bag.
    works_to_pick_from = bag_of_recent_items

    # Now, pick a few of these out of the bag at random to show.
    # Reshuffle the bag every now and then.
    srand @@arbitrary_number
    works_to_pick_from.sort_by{rand}[0...how_many_works_to_show]
  end
  helper_method :recent_items

  def bag_of_recent_items
    how_many_works_in_bag = 15
    conditions =  {'read_access_group_ssim'=>'public'}
    sort_by = ["system_modified_dtsi desc"]
    opts = {:rows=>how_many_works_in_bag, :sort=>sort_by}
    @@bag_of_recent_items ||= GenericWork.search_with_conditions( conditions, opts)
  end

  def featured_collection_image_link(work_id, title)
    begin
      @solr_doc ||= SolrDocument.find(work_id)
    rescue
      return view_context.link_to("Image not in this repository", "#")
    end
    view_context.link_to(@solr_doc.title.first, curation_concerns_generic_work_path(@solr_doc.id))
  end
  helper_method :featured_collection_image_link


end
