# Gives the class of the form.
class BatchUploadFormService < CurationConcerns::WorkFormService
  def self.form_class(_ = nil)
    ::BatchUploadForm
  end
end
