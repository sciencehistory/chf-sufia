class GenericFilePresenter < Sufia::GenericFilePresenter

  self.terms = [:resource_type, :genre, :title, :creator, :contributor, :description, :tag, :rights,
      :publisher, :date_created, :subject, :language, :identifier, :based_near, :related_url]

end
