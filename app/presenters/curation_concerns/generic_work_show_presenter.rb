module CurationConcerns
  class GenericWorkShowPresenter < Sufia::WorkShowPresenter
    # There's no such thing as self.terms in the presenter anymore.

    delegate :genre_string, to: :solr_document

    #self.terms += [:title, :identifier,
    #  ].concat(Rails.configuration.makers.keys).concat(
    #    [:date_of_work]).concat(
    #    Rails.configuration.places.keys).concat(
    #    [
    #    :resource_type, :genre_string,
    #    :medium,
    #    :extent,
    #    :language,
    #    :description,
    #    :inscription,
    #    :subject,
    #    :division,
    #    :series_arrangement,
    #    :physical_container,
    #    :related_url,
    #    :rights,
    #    :rights_holder,
    #    :credit_line,
    #    :additional_credit,
    #    :file_creator,
    #    :admin_note,
    #    ])
  end
end
