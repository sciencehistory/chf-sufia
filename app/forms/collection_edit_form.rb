class CollectionEditForm < Sufia::Forms::CollectionForm
  include HydraEditor::Form
  include ::CollectionFormBehavior

  def primary_terms
    [:title, :description, :related_url]
  end
  def secondary_terms
    []
  end
end
