# Normally blacklight_oai_provider adds routes on to CatalogController, but
# we provide our own controller instead.
#
# This way we can override SearchBuilder to insist on only GenericWorks, not
# collections. There might be another/better way to do this with blacklight_oai_provider,
# but it's pretty mysterious.
class OaiPmhController < CatalogController
  include BlacklightOaiProvider::Controller

  configure_blacklight do |config|
    config.oai = {
      provider: {
        repository_name: 'Science History Institute',
        repository_url: "#{CHF::Env.lookup!(:app_url_base)}/oai",  #??? "?verb=ListRecords&metadataPrefix=oai_dc",
        record_prefix: 'oai:sciencehistoryorg',
        admin_email: 'digital@sciencehistory.org',
        sample_id: GenericWork.first.try(:id)
      },
      document: {
        # http://oval.base-search.net/ validation recommends at least 100
        limit: 100           # number of records returned with each request, default: 15
      }
    }
  end

  # Kinda hacky way I don't entirely understand to force search builder to only
  # return works.
  def search_builder(*args)
    super.with(f: { generic_type_sim: ["Work"] } )
  end

  protected


  # gah, blacklight_oai_provider is hard-coded to expect a "oai_catalog_url" route helper,
  # can work around.
  def oai_catalog_url(*args)
    oai_pmh_oai_url(*args)
  end
  helper_method :oai_catalog_url
end
