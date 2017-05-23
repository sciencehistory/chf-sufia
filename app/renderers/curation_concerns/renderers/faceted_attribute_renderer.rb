# Over-ridden from CurationConcerns to fix double-escaping bug. Fixed in
# Hyrax at https://github.com/projecthydra-labs/hyrax/pull/1027
# prob not excpted until hyrax 2.0 :(

if Gem.loaded_specs["hyrax"] && Gem.loaded_specs["hyrax"].version >= Gem::Version.new('2.0')
  msg = "\n\nPlease check and make sure this patch to fix html-escaping in FacetedAttriuteRenderer is still needed at #{__FILE__}:#{__LINE__}\n\n"
  $stderr.puts msg
  Rails.logger.warn msg
end

module CurationConcerns
  module Renderers
    class FacetedAttributeRenderer < AttributeRenderer
      private

        def li_value(value)
          link_to(ERB::Util.h(value), search_path(value))
        end

        def search_path(value)
          Rails.application.routes.url_helpers.search_catalog_path(:"f[#{search_field}][]" => value)
        end

        def search_field
          ERB::Util.h(Solrizer.solr_name(options.fetch(:search_field, field), :facetable, type: :string))
        end
    end
  end
end
