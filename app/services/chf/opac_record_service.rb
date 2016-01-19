require 'oauth2'

module CHF

  class InvalidOpacRecordNumber < StandardError; end
  class OpacConnectionError < StandardError; end

  class OpacRecordService

    def initialize(params = {})
      @host = params.fetch(:host, Rails.application.secrets.sierra_host || 'https://sandbox.iii.com')
      @path = params.fetch(:path, '/iii/sierra-api/v2')
      @api_key = params.fetch(:api_key, Rails.application.secrets.sierra_key || 'NO_GOOD_DEFAULT')
      @client_secret = params.fetch(:client_secret,  Rails.application.secrets.sierra_secret ||'NO_GOOD_DEFAULT')
      # creating the client creates an object but doesn't actually make a connection; that's done when we ask for a token.
      @client = OAuth2::Client.new(@api_key, @client_secret, :site => @host, :token_url => "#{@path}/token")
    end

    # param bibnum is a bibliographic record number
    # returns a hash of data about the record
    def get_bib(bibnum)
      cbn = clean_bibnum(bibnum)
      if cbn.empty?
        Rails.logger.error "ERROR: OpacRecordService#get_bib called with invalid bib number #{bibnum}"
        raise InvalidOpacRecordNumber, 'invalid bib number'
      else
        begin
          response = token.get("#{@path}/bibs/#{cbn}")
        rescue OAuth2::Error => e
          Rails.logger.error "ERROR: OpacRecordService#get_bib #{e}"
          raise OpacConnectionError, 'error connecting or authenticating with the opac'
        else
          # It may seem like we should just return the unparsed (json) body, since
          # the controller will pull from here and then need to turn it into json again.
          # But I expect to do lots of data processing here in /services; therefore
          # controller should expect the hash and convert it back to json for consumption.
          response.parsed
        end
      end
    end

    private

      # May throw OAuth2::Error
      # tokens last 6 minutes -- let's get a new one every time!
      def token
        @client.client_credentials.get_token
      end

      # No letters, no punctuation, no checksums (first 7 digits)
      # turn something like B10691054
      # into something like 1069105
      def clean_bibnum(num)
        /\d{7}/.match(num).to_s
      end

  end
end
