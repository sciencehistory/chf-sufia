module HeroImageHelper
  def hero_link(hero_id)
    begin
      solr_doc = SolrDocument.find(hero_id)
    rescue
      # handle dev case
      return link_to("Hero Image not in this repository", "#")
    end
    link_to(solr_doc.title.first, curation_concerns_generic_work_path(solr_doc.id))
  end
end
