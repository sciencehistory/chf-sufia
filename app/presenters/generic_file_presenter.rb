class GenericFilePresenter < Sufia::GenericFilePresenter

  self.terms = [:abstract, :title, :resource_type, :genre_string, :creator,
      :contributor, :depicted, :description, :extent, :tag, :rights,
      :publisher, :date_created, :date_original, :date_published, :subject,
      :language, :identifier, :inscription, :related_url, :artist,
      :author, :interviewee, :interviewer, :manufacturer, :medium,
      :photographer, :place_of_interview, :place_of_manufacture,
      :place_of_publication, :provenance]

end
