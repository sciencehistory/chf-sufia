require 'oauth2'

class OpacRecordService

  def initialize(params = {})
    @host = params.fetch(:host, Rails.application.secrets.sierra_host || 'https://sandbox.iii.com')
    @path = params.fetch(:path, '/iii/sierra-api/v2')
    @api_key = params.fetch(:api_key, Rails.application.secrets.sierra_key || 'NO_GOOD_DEFAULT')
    @client_secret = params.fetch(:client_secret,  Rails.application.secrets.sierra_secret ||'NO_GOOD_DEFAULT')
    # creating the client creates an object but doesn't actually make a connection; that's done when we ask for a token.
    @client = OAuth2::Client.new(@api_key, @client_secret, :site => @host, :token_url => "#{@path}/token")
  end

  def get_bib(bibnum)
    # TODO: clean bibnum to be digits only
    response = token.get("#{@path}/bibs/#{bibnum}")
    rescue OAuth2::Error => e
      Rails.logger.error "ERROR: OpacRecordService#get_bib #{e}"
      { 'error' => 'error connecting or authenticating with the opac' }
    else
      response.parsed
  end

  private

    # May throw OAuth2::Error
    # tokens last 6 minutes -- let's get a new one every time!
    def token
      @client.client_credentials.get_token
    end

end
