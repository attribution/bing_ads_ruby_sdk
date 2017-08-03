require 'yaml'
require 'logger'
require 'bing_ads_ruby_sdk/service'
require 'bing_ads_ruby_sdk/header'

module BingAdsRubySdk
  class Api

    attr_reader :services, :header

    # @param config [Hash] shared soap header customer parameters
    # @option config [Symbol] :id customer id
    # @option config [Symbol] :account_id customer account_id
    def customer(config)
      header.customer = config
    end

    # @param version [Symbol] API version, used to choose WSDL configuration version
    # @param environment [Symbol]
    # @option environment [Symbol] :production Use the production WSDL configuration
    # @option environment [Symbol] :sandbox Use the sandbox WSDL configuration
    # @param log_level [Logger::Severity]
    # @param credentials [Hash]
    # @option credentials [String] :developer_token The developer token used to access the API
    # @option credentials [String] :client_id The client ID used to acces the API
    def initialize(version: :v11,
                   environment: :production,
                   log_level: Logger::INFO,
                   credentials: {})

      @header = Header.new(credentials)

      BingAdsRubySdk.logger = Logger.new(STDERR)
      BingAdsRubySdk.logger.level = log_level

      # Get the URLs for the WSDL that defines the services on the API
      @services = YAML.load_file(
        "#{File.expand_path('../', __FILE__)}/config/#{version}.yml"
      )[environment.to_s.upcase]

      # Create a service object based on the WSDL in each configuration entry
      services.each do |serv, url|
        BingAdsRubySdk.logger.info("Defining service #{serv} accessors")
        # TODO : hmm or define_singleton_method ?
        self.class.send(:attr_reader, serv)

        instance_variable_set("@#{serv}", Service.new(url, header))
      end
    end
  end
end
