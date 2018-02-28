module CitationRenderingHelper

  # pulls the indexed citation out of solr
  def citation_for_work(presenter)
    # it is safe html in solr
    cit = presenter.solr_document["citation_html_ss"]
    cit && cit.html_safe
  end

end
