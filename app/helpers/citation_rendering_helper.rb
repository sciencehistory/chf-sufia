module CitationRenderingHelper
  # reuse this style cause it's expensive to load. Hope it's concurrency safe!
  def self.csl_chicago_style
    @csl_chicago_style ||= ::CSL::Style.load("chicago-note-bibliography")
  end

  # similar to csl_chicago_style
  def self.csl_en_us_locale
    @csl_en_us_locale ||= ::CSL::Locale.load("en-US")
  end

  # creates citation from presenter using CitableAttributes, and ruby CSL
  def citation_for_work(presenter)
    csl_data = CHF::CitableAttributes.new(
      presenter, collection: presenter.in_collection_presenters.first,
      parent_work: presenter.parent_work_presenters.first
    ).as_csl_json.stringify_keys

    citation_item = CiteProc::CitationItem.new(id: csl_data["id"] || "id") do |c|
      c.data = CiteProc::Item.new(csl_data)
    end

    renderer = CiteProc::Ruby::Renderer.new :format => CiteProc::Ruby::Formats::Html.new,
      :locale => CitationRenderingHelper.csl_en_us_locale

    renderer.render(citation_item, CitationRenderingHelper.csl_chicago_style.bibliography).html_safe
  end

end
