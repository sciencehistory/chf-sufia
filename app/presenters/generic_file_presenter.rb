class GenericFilePresenter < Sufia::GenericFilePresenter

  # this list of terms is used for:
  #   allowing the fields to be edited
  #   showing the fields on the item page
  self.terms = [:identifier, :title, :resource_type, :genre_string,
      :description, :extent, :rights, :rights_holder,
      :publisher, :date_of_work, :date_of_publication, :subject,
      :language, :related_url,
      :medium, :place_of_interview, :place_of_manufacture,
      :series_arrangement, :physical_container,
      :place_of_publication, :provenance].concat Sufia.config.makers.keys

  # Add a new list for creating form elements on the edit pages
  #   (since we've combined many of the fields into 'maker')
  def edit_field_terms
    [:identifier, :title, :maker, :resource_type, :genre_string,
      :description, :extent, :rights, :rights_holder,
      :publisher, :date_of_work, :date_of_publication, :subject,
      :language, :related_url,
      :medium, :place_of_interview, :place_of_manufacture,
      :physical_container,
      :place_of_publication, :provenance]
  end

  # We need these as hidden fields or else data deletion doesn't work.
  def hidden_field_terms
    Sufia.config.makers.keys
  end

  # post-upload edit form has a "show more" button; we want
  # to control order independently here.
  def above_fold_terms
    [:maker,
     :date_of_work,
     :date_of_publication,
     :resource_type,
     :genre_string,
     :identifier,
     :rights,
    ]
  end
  def below_fold_terms
    edit_field_terms - above_fold_terms - [:title]
  end

end
