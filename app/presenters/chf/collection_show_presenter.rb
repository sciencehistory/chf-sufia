module CHF
  class CollectionShowPresenter < Sufia::CollectionPresenter

    # returns arg that can be passed to 'image_tag'
    # will return default image if needed, or pass `default: nil` or your own path
    def thumbnail_src(default: 'default_collection.svg')
      relative_path = self.solr_document.first(Solrizer.solr_name('representative_image_path', :displayable)).presence || default
      "collections/#{relative_path}" if relative_path
    end

  end
end
