class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include Sufia::SearchBuilder

  # This applies appropriate access controls to all solr queries
  self.default_processor_chain += [:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr]

end
