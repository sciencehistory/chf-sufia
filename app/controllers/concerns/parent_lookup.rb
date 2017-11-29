module ParentLookup

  protected

  # For a list of Solr results with 'id' methods, look up all direct parents in one
  # (weird, hacky) solr query, return a hash where keys are all children, and values are
  # an array of parents. Used so we can show parents on search _results_ pages, by
  # looking up in hash.
  #
  # Assumes mixed into a controller with a #search_builder that has an #apply_gated_discovery
  # method, so we an apply access controls to parents in a hacky way.
  def parent_lookup_hash(children)
    children_by_id = children.collect { |r| [r.id, r]}.to_h
    if children_by_id.empty?
      return {}
    end

    # Fetch all the parents, with access controls, this is one hacky fragile way to do it.
    # hackily get gated access controls out of search builder
    gated_params = {}
    search_builder.send(:apply_gated_discovery, gated_params)
    fq = gated_params[:fq]

    # Not collections
    query = "NOT(has_model_ssim:Collection) AND (#{children_by_id.keys.collect { |id| "member_ids_ssim:#{id}" }.join(" OR ")})"
    parent_results = ActiveFedora::SolrService.query(query, rows: 1000, fq: fq)
    # wrap in SolrDocument for consistency
    parent_results.collect! { |result|  SolrDocument.new(result) }

    # We have parents, we don't really know which children they go with, but we know ALL the children
    # of each parent, just store it for lookup in a hash. Cause we don't have a custom presenter
    # for child to store it on either, we'll just put it in iVar hash. :(
    lookup_hash = {}

    # Assign parents to relevant children. Not very performant, but here we go.
    parent_results.each do |parent|
      parent["member_ids_ssim"].each do |child_id|
        lookup_hash[child_id] ||= []
        lookup_hash[child_id] << parent
      end
    end
    return lookup_hash
  end
end
