# frozen_string_literal: true

# Note: In Sufia 7.x at all, this is _not_ used by the CatalogController,
# which uses it's own `Sufia::CatalogSearchBuilder` instead. Unclear how
# to customize it. This may be true of other sufia/hyrax searchbuilders as well.
# https://github.com/projecthydra-labs/hyrax/issues/707
#
# See also .config/initializers/sufia_catalog_search_builder_overrides.rb
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  include Hydra::AccessControlsEnforcement
  include CurationConcerns::SearchFilters
end
