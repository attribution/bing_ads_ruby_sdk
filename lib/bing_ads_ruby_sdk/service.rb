require 'lolsoap'
require 'thread'
require 'bing_ads_ruby_sdk/utils'
require 'net/http'
require 'open-uri'

module BingAdsRubySdk
  # Manages communication with the a defined SOAP service on the API
  class Service
    SEMAPHORE = Mutex.new

    attr_reader :client, :shared_header, :abstract_types

    def initialize(client, shared_header)
      @client = client
      @shared_header = shared_header
      client.wsdl.namespaces['xsi'] = 'http://www.w3.org/2001/XMLSchema-instance'
      operations.keys.each do |op|
        BingAdsRubySdk.logger.debug("Defining operation : #{op}")
        define_singleton_method(Utils.snakize(op)) do |body = false|
          request(op, body)
        end
      end
    end

    def operations
      client.wsdl.operations
    end

    def http_request(req)
      url = URI(req.url)
      Net::HTTP.start(url.hostname,
                      url.port,
                      use_ssl: url.scheme == 'https') do |http|
        http.post(url.path, req.content, req.headers)
      end
    end

    def parse_response(req, raw)
      client.response(req, raw.body).body_hash.tap do |b_h|
        BingAdsRubySdk.logger.debug(b_h)
        BingAdsRubySdk::Errors::ErrorHandler.parse_errors!(b_h)
      end
    end

    def request(name, body)
      req = client.request(name)
      req.header.content(shared_header.content)
      SEMAPHORE.synchronize do
        AbstractType.wsdl = client.wsdl
        req.body.content(body) if body
      end
      BingAdsRubySdk.logger.debug("Operation : #{name}")
      BingAdsRubySdk.logger.debug(req.content)

      raw_response = http_request(req)
      parse_response(req, raw_response)
    end
  end
end
