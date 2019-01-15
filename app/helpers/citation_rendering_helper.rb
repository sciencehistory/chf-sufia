module CitationRenderingHelper
  # creates citation from presenter using CitableAttributes, and ruby CSL
  def citation_for_work(presenter)
    CHF::CitableAttributes::Renderer.from_work_presenter(presenter).render_html
  end
end
