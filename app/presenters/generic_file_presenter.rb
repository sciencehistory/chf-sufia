class GenericFilePresenter < Sufia::GenericFilePresenter

  # this list of terms is used for:
  #   allowing the fields to be edited
  #   showing the fields on the item page
  self.terms = [:title, :identifier,
    ].concat(Sufia.config.makers.keys).concat(
      [
      :date_of_work,
      :place_of_interview, :place_of_manufacture, :place_of_publication,
      :resource_type, :genre_string,
      :medium,
      :extent,
      :language,
      :description,
      :subject,
      :series_arrangement,
      :physical_container,
      :rights,
      :rights_holder,
      :provenance,
      :publisher, # move to maker
      :related_url,
      ])

  # Add a new list for creating form elements on the edit pages
  #   (since we've combined many of the fields into 'maker')
  def edit_field_terms
    [:title, :identifier, :maker,
      :date_of_work,
      :place_of_interview, :place_of_manufacture, :place_of_publication,
      :resource_type, :genre_string,
      :medium,
      :extent,
      :language,
      :description,
      :subject,
      :series_arrangement,
      :physical_container,
      :rights,
      :rights_holder,
      :provenance,
      :publisher, # move to maker
      :related_url,
    ]
  end

  # We need these as hidden fields or else data deletion doesn't work.
  def hidden_field_terms
    Sufia.config.makers.keys
  end

  # post-upload edit form has a "show more" button; we want
  # to control order independently here.
  def above_fold_terms
    [:identifier,
     :maker,
     :date_of_work,
     :resource_type,
     :genre_string,
     :rights,
    ]
  end
  def below_fold_terms
    edit_field_terms - above_fold_terms - [:title]
  end

end
