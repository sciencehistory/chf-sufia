class WorkShowPresenter < Sufia::WorkShowPresenter

  # this list of terms is used for:
  #   allowing the fields to be edited
  #   showing the fields on the item page
  self.terms = [:title, :identifier,
    ].concat(Rails.configuration.makers.keys).concat(
      [:date_of_work]).concat(
      Rails.configuration.places.keys).concat(
      [
      :resource_type, :genre_string,
      :medium,
      :extent,
      :language,
      :description,
      :inscription,
      :subject,
      :division,
      :series_arrangement,
      :physical_container,
      :related_url,
      :rights,
      :rights_holder,
      :credit_line,
      :additional_credit,
      :file_creator,
      :admin_note,
      ])

  # Add a new list for creating form elements on the edit pages
  #   (since we've combined many of the fields into 'maker')
  def edit_field_terms
    [:title, :identifier, :maker,
      :date_of_work,
      :place,
      :resource_type, :genre_string,
      :medium,
      :extent,
      :language,
      :description,
      :inscription,
      :subject,
      :division,
      :series_arrangement,
      :physical_container,
      :related_url,
      :rights,
      :rights_holder,
      :credit_line,
      :additional_credit,
      :file_creator,
      :admin_note,
    ]
  end

  # We need these as hidden fields or else data deletion doesn't work.
  def hidden_field_terms
    Rails.configuration.makers.keys.concat(Rails.configuration.places.keys)
  end

  # post-upload edit form has a "show more" button; we want
  # to control order independently here.
  def above_fold_terms
    [:identifier,
     :maker,
     :date_of_work,
     :resource_type,
     :genre_string,
    ]
  end
  def below_fold_terms
    edit_field_terms - above_fold_terms - [:title]
  end

  # give form access to attributes methods so it can build nested forms.
  delegate :date_of_work_attributes=, :to => :model
  delegate :inscription_attributes=, :to => :model
  delegate :additional_credit_attributes=, :to => :model

end
