require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = 'https://digital.sciencehistory.org'

SitemapGenerator::Sitemap.create do
  image_service_class = ImageServiceHelper.image_url_service_class(CHF::Env.lookup(:image_server_for_thumbnails))

  add about_path, changefreq: 'monthly'
  add policy_path, changefreq: 'monthly'
  add faq_path, changefreq: 'monthly'
  add contact_path, changefreq: 'monthly'

  add search_catalog_path, changefreq: 'daily'

  read_solr_field = Solrizer.solr_name('read_access_group', :symbol)

  CHF::SyntheticCategory.all.collect(&:slug).each do |slug|
    add synthetic_category_path(slug), changefreq: 'weekly'
  end

  Collection.find_each(read_solr_field => 'public') do |c|
    add collection_path(c), changefreq: 'weekly', lastmod: nil
  end

  GenericWork.find_each(read_solr_field => 'public') do |w|
    presenter = CurationConcerns::GenericWorkShowPresenter.new(w, Ability.new(nil))

    # spec says max 1000 images.
    image_urls = presenter.viewable_member_presenters.slice(0, 1000).collect do |member|
      image_service = image_service_class.new(file_set_id: member.representative_file_set_id, file_id: member.representative_file_id, checksum: member.representative_checksum)
      image_service.thumb_url(size: :large, density_descriptor: "2X")
    end

    add curation_concerns_generic_work_path(w),
        changefreq: 'monthly',
        lastmod: nil,
        images: image_urls.collect { |url| { loc: url } }
  end
end

