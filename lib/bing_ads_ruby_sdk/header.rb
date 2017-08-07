require 'bing_ads_ruby_sdk/oauth2/authorization_code'

module BingAdsRubySdk
  # Contains the SOAP Request header informations
  class Header
    attr_reader :credentials, :token
    attr_accessor :customer

    # @param credentials [Hash] to be used for API authorization
    # @option credentials :developer_token [String]
    # @option credentials :client_id [String]
    def initialize(credentials, oauth_store)
      @credentials = credentials
      @token = BingAdsRubySdk::OAuth2::AuthorizationCode.new(
        store:           oauth_store,
        developer_token: credentials[:developer_token],
        client_id:       credentials[:client_id]
      )
    end

    # @return [Hash] Authorization and identification data that will be added to the SOAP header
    def content
      {
        authentication_token: token.fetch_or_refresh,
        developer_token:      credentials[:developer_token],
        customer_id:          customer[:id],
        customer_account_id:  customer[:account_id]
      }
    end
  end
end
