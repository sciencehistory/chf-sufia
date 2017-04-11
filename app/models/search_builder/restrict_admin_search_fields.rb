class SearchBuilder
  module RestrictAdminSearchFields
    extend ActiveSupport::Concern

    mattr_accessor :admin_only_search_fields
    self.admin_only_search_fields = [
      ActiveFedora.index_field_mapper.solr_name("admin_note", :stored_searchable)
    ]

    included do
      self.default_processor_chain += [:exclude_admin_only_search_fields]
    end

    def exclude_admin_only_search_fields(solr_params)
      unless scope.respond_to?(:staff_user?) && scope.staff_user?
        # delete all protected search fields
        regexp_or = Regexp.union(admin_only_search_fields)
        solr_params[:qf] = solr_params[:qf].
                            split(/\s+/).
                            delete_if { |f| f=~ /\A#{ regexp_or }(\^[\d\.]+)?\Z/ }.
                            join(" ")
      end
    end
  end
end
