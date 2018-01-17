require 'rubygems'
require 'sitemap_generator'

SitemapGenerator::Sitemap.default_host = 'https://digital.sciencehistory.org'

SitemapGenerator::Sitemap.create do
  add about_path, changefreq: 'monthly'
  add policy_path, changefreq: 'monthly'
  add faq_path, changefreq: 'monthly'
  add contact_path, changefreq: 'monthly'

  add search_catalog_path, changefreq: 'daily'

  read_solr_field = Solrizer.solr_name('read_access_group', :symbol)

  GenericWork.find_each(read_solr_field => 'public') do |w|
    add curation_concerns_generic_work_path(w),
        changefreq: 'monthly',
        lastmod: nil
  end

  Collection.find_each(read_solr_field => 'public') do |c|
    add collection_path(c), changefreq: 'weekly', lastmod: nil
  end


end

