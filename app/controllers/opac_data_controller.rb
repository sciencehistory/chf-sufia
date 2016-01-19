class OpacDataController < ActionController::Base
  respond_to :json

  def load_bib()
    begin
      opac = CHF::OpacRecordService.new
      data = opac.get_bib(params[:rec_num])
      respond_with data.to_json
    rescue CHF::OpacConnectionError => e
      data = { 'error' => e.message }
      respond_with data.to_json, status: 500
    rescue CHF::InvalidOpacRecordNumber => e
      data = { 'error' => e.message }
      respond_with data.to_json, status: 404
    end
  end

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

end
