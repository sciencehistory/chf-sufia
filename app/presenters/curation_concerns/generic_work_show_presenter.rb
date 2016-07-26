module CurationConcerns
  class GenericWorkShowPresenter < Sufia::WorkShowPresenter
    # There's no such thing as self.terms in the presenter anymore.

    delegate :genre_string, :medium, :physical_container, :creator_of_work,
      :artist, :author, :addressee, :interviewee, :interviewer,
      :manufacturer, :photographer, :place_of_interview,
      :place_of_manufacture, :place_of_creation, :place_of_publication,
      :extent, :division, :series_arrangement, :rights_holder,
      :credit_line, :additional_credit, :file_creator, :admin_note,
      :inscription, :date_of_work,
      to: :solr_document
  end
end
