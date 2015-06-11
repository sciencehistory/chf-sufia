class GenericFilePresenter < Sufia::GenericFilePresenter

  self.terms = [:title, :resource_type, :genre_string, :creator, :contributor, :description, :tag, :rights,
      :publisher, :date_created, :subject, :language, :identifier, :based_near, :related_url, :artist,
      :author, :interviewee, :interviewer, :manufacturer, :photographer]

end
