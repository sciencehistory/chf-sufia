# Override of Sufia 7.3 MyController, so we can remove the year_facet
# from facets, after being copied from CatalogController.
#
# It was far too complicated to get it to work properly in sufia 'my' controllers.

class MyController < ApplicationController
  include Sufia::MyControllerBehavior

  blacklight_config.facet_fields.delete_if { |field, | field == solr_name('year_facet', type: :integer) }
end
