class GenericFilePresenter < Sufia::GenericFilePresenter

  self.terms = [:title, :resource_type, :genre_string, :creator,
      :contributor, :description, :extent, :rights,
      :publisher, :date_original, :date_published, :subject,
      :language, :identifier, :related_url, :artist,
      :author, :interviewee, :interviewer, :manufacturer, :medium,
      :photographer, :place_of_interview, :place_of_manufacture,
      :place_of_publication, :provenance]

end
