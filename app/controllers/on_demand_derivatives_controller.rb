# Use for our whole-work multi-image derivatives: PDF, zip. To create them on
# demand, via a background job, and provide JSON status messages for front-end
# to display progress and redirect to download, etc.
class OnDemandDerivativesController < ApplicationController
  before_action do
    # I dunno why we authorize the solr_document, but that appears to be
    # what the stack does.
    authorize! :show, presenter.solr_document
  end


  # Returns a JSON hash with status of on-demand derivative, including a URL
  # if it's available now.
  def pdf
    record = OnDemandDerivative.find_or_create_record(work_id, "pdf", work_presenter: presenter)

    render json: record.as_json(methods: (record.success? ? "url" : nil))
  end

  def zip
    record = OnDemandDerivative.find_or_create_record(work_id, "zip", work_presenter: presenter)

    render json: record.as_json(methods: (record.success? ? "url" : nil))
  end


  protected

  def work_id
    @work_id = params.require(:id)
  end

  def presenter
    @presenter ||= CurationConcerns::GenericWorkShowPresenter.new(
      SolrDocument.find(work_id),
      Ability.new(current_user)
    )
  end
end
