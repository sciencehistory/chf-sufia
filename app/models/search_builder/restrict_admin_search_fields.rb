class SearchBuilder
  module RestrictAdminSearchFields
    extend ActiveSupport::Concern

    mattr_accessor :admin_only_search_fields
    self.admin_only_search_fields = [
      ActiveFedora.index_field_mapper.solr_name("admin_note", :stored_searchable),
      ActiveFedora.index_field_mapper.solr_name("file_creator", :stored_searchable),
      ActiveFedora.index_field_mapper.solr_name("identifier", :stored_searchable)
    ]

    included do
      self.default_processor_chain += [:exclude_admin_only_search_fields]
    end

    def exclude_admin_only_search_fields(solr_params)
      unless scope.respond_to?(:staff_user?) && scope.staff_user?
        if solr_params["qf"].present?
          solr_params["qf"] = _remove_admin_only_fields_from_solr_value(solr_params["qf"], admin_only_search_fields)
        end
        if solr_params["pf"].present?
          solr_params["pf"] = _remove_admin_only_fields_from_solr_value(solr_params["pf"], admin_only_search_fields)
        end
      end
    end

    protected

    def _remove_admin_only_fields_from_solr_value(array, fields)
      regexp_or = Regexp.union(admin_only_search_fields)
      array.
        split(/\s+/).
        delete_if { |f| f=~ /\A#{ regexp_or }(\^[\d\.]+)?\Z/ }.
        join(" ")
    end
  end
end
