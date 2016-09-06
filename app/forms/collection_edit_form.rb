class CollectionEditForm < Sufia::Forms::CollectionForm
  include HydraEditor::Form

  def primary_terms
    [:title, :description, :related_url]
  end
  def secondary_terms
    []
  end
end
