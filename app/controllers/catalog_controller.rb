class CatalogController < ApplicationController
  include Hydra::Catalog
  include Hydra::Controller::ControllerBehavior
  include Sufia::Catalog
  include BlacklightAdvancedSearch::Controller

  # These before_filters apply the hydra access controls
  before_filter :enforce_show_permissions, only: :show
  skip_before_filter :default_html_head

  def self.uploaded_field
    solr_name('system_create', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('system_modified', :stored_sortable, type: :date)
  end

  def self.chf_search_fields
    [
      solr_name("title", :stored_searchable),
      solr_name("depositor"),
      solr_name("description", :stored_searchable),
      solr_name("subject", :stored_searchable),
      solr_name("language", :stored_searchable),
      solr_name("identifier", :stored_searchable),
      solr_name("related_url", :stored_searchable),
      solr_name("artist", :stored_searchable),
      solr_name("author", :stored_searchable),
      solr_name("addressee", :stored_searchable),
      solr_name("creator_of_work", :stored_searchable),
      solr_name("contributor", :stored_searchable),
      solr_name("engraver", :stored_searchable),
      solr_name("interviewee", :stored_searchable),
      solr_name("interviewer", :stored_searchable),
      solr_name("manufacturer", :stored_searchable),
      solr_name("photographer", :stored_searchable),
      solr_name("printer_of_plates", :stored_searchable),
      solr_name("publisher", :stored_searchable),
      solr_name("place_of_interview", :stored_searchable),
      solr_name("place_of_manufacture", :stored_searchable),
      solr_name("place_of_publication", :stored_searchable),
      solr_name("place_of_creation", :stored_searchable),
      solr_name("additional_title", :stored_searchable),
      solr_name("admin_note", :stored_searchable),
      solr_name("division", :stored_searchable),
      solr_name("file_creator", :stored_searchable),
      solr_name("genre_string", :stored_searchable),
      solr_name("medium", :stored_searchable),
      solr_name("physical_container", :stored_searchable),
      solr_name("resource_type", :stored_searchable),
      solr_name("rights", :stored_searchable),
      solr_name("series_arrangement", :stored_searchable),
      solr_name("inscription", :stored_searchable),
      solr_name("additional_credit", :stored_searchable),
    ]
  end

  configure_blacklight do |config|
    # Turning this off to prevent Solr stack overflows
    # see https://github.com/projectblacklight/blacklight/wiki/Blacklight-Autocomplete
    config.autocomplete_enabled = false

    config.view.gallery.partials = [:index_header, :index]
    config.view.masonry.partials = [:index]
    config.view.slideshow.partials = [:index]

    config.index.document_presenter_class = ChfIndexPresenter

    config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    config.show.partials.insert(1, :openseadragon)
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}

    config.search_builder_class = Sufia::SearchBuilder

    # Show gallery view
    config.view.gallery.partials = [:index_header, :index]
    config.view.slideshow.partials = [:index]

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10,
      qf: "title_tesim name_tesim"
    }

    # solr field configuration for document/show views
    config.index.title_field = solr_name("title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_field = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field solr_name("subject", :facetable), label: "Subject", limit: 5
    config.add_facet_field solr_name("maker_facet", :facetable), label: "Maker/Creator", limit: 5
    config.add_facet_field solr_name('place_facet', :facetable), label: "Place", limit: 5
    config.add_facet_field solr_name("genre_string", :facetable), label: "Genre", limit: 5
    config.add_facet_field solr_name("resource_type", :facetable), label: "Resource Type", limit: 5
    config.add_facet_field solr_name("medium", :facetable), label: "Medium", limit: 5
    config.add_facet_field solr_name("language", :facetable), label: "Language", limit: 5
    config.add_facet_field solr_name("division", :facetable), label: "Division", limit: 5
    config.add_facet_field solr_name("rights", :facetable), helper_method: :license_label, label: "Rights", limit: 5

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name("title", :stored_searchable), label: "Title", itemprop: 'name', if: false
    config.add_index_field solr_name("description", :stored_searchable), label: "Description", itemprop: 'description', helper_method: :format_description_for_index
    config.add_index_field solr_name("subject", :stored_searchable), label: "Subject", itemprop: 'about', link_to_search: solr_name("subject", :facetable)
    config.add_index_field solr_name("artist", :stored_searchable), label: "Artist", itemprop: 'artist', link_to_search: solr_name("artist", :facetable)
    config.add_index_field solr_name("author", :stored_searchable), label: "Author", itemprop: 'author', link_to_search: solr_name("author", :facetable)
    config.add_index_field solr_name("addressee", :stored_searchable), label: "Addressee", itemprop: 'addressee', link_to_search: solr_name("addressee", :facetable)
    config.add_index_field solr_name("creator_of_work", :stored_searchable), label: "Creator", itemprop: 'creator_of_work', link_to_search: solr_name("creator_of_work", :facetable)
    config.add_index_field solr_name("contributor", :stored_searchable), label: "Contributor", itemprop: 'contributor', link_to_search: solr_name("contributor", :facetable)
    config.add_index_field solr_name("engraver", :stored_searchable), label: "Engraver", itemprop: 'engraver', link_to_search: solr_name("engraver", :facetable)
    config.add_index_field solr_name("interviewee", :stored_searchable), label: "Interviewee", itemprop: 'interviewee', link_to_search: solr_name("interviewee", :facetable)
    config.add_index_field solr_name("interviewer", :stored_searchable), label: "Interviewer", itemprop: 'interviewer', link_to_search: solr_name("interviewer", :facetable)
    config.add_index_field solr_name("manufacturer", :stored_searchable), label: "Manufacturer", itemprop: 'manufacturer', link_to_search: solr_name("manufacturer", :facetable)
    config.add_index_field solr_name("photographer", :stored_searchable), label: "Photographer", itemprop: 'photographer', link_to_search: solr_name("photographer", :facetable)
    config.add_index_field solr_name("printer_of_plates", :stored_searchable), label: "Printer_of_plates", itemprop: 'printer_of_plates', link_to_search: solr_name("printer_of_plates", :facetable)
    config.add_index_field solr_name("publisher", :stored_searchable), label: "Publisher", itemprop: 'publisher', link_to_search: solr_name("publisher", :facetable)
    config.add_index_field solr_name("depositor"), label: "Owner", helper_method: :link_to_profile
    config.add_index_field solr_name("language", :stored_searchable), label: "Language", itemprop: 'inLanguage', link_to_search: solr_name("language", :facetable)
    #config.add_index_field solr_name("date_uploaded", :stored_sortable, type: :date), label: "Date Uploaded", itemprop: 'datePublished'
    #config.add_index_field solr_name("date_modified", :stored_sortable, type: :date), label: "Date Modified", itemprop: 'dateModified'
    #config.add_index_field solr_name("date_created", :stored_searchable), label: "Date Created", itemprop: 'dateCreated'
    config.add_index_field solr_name("rights", :stored_searchable), label: "Rights", helper_method: :rights_statement_links
    config.add_index_field solr_name("resource_type", :stored_searchable), label: "Resource Type", link_to_search: solr_name("resource_type", :facetable)
    config.add_index_field solr_name("file_format", :stored_searchable), label: "File Format", link_to_search: solr_name("file_format", :facetable)
    #config.add_index_field solr_name("identifier", :stored_searchable), label: "Identifier", helper_method: :index_field_link, field_name: 'identifier'


    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields', include_in_advanced_search: false) do |field|
      all_names = chf_search_fields.join(" ")
      title_name = solr_name("title", :stored_searchable)
      field.solr_parameters = {
        qf: "#{all_names} file_format_tesim all_text_timv",
        pf: title_name.to_s
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance"
    config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  # disable the bookmark control from displaying in gallery view
  # Sufia doesn't show any of the default controls on the list view, so
  # this method is not called in that context.
  def render_bookmarks_control?
    false
  end
end
