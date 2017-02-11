require 'appnexusapi/faraday/raise_http_error'

module AppnexusApi
  class AppnexusApi::Connection
    RATE_EXCEEDED_DEFAULT_TIMEOUT = 15

    RATE_LIMIT_WAITER = Proc.new do |exception, try, elapsed_time, next_interval|
      seconds = /Retry after \d+s/.match(exception.message)[1] || RATE_EXCEEDED_DEFAULT_TIMEOUT
      seconds += RATE_EXCEEDED_DEFAULT_TIMEOUT # Just to be sure we waited long enough
      puts "WARN: Rate limit exceeded; retrying after sleeping for #{seconds}s..."
      sleep(seconds)
    end

    attr_reader :connection, :logger

    def initialize(config)
      @config = config
      @config['uri'] ||= 'https://api.appnexus.com/'
      @api_debug = ENV['APPNEXUS_API_DEBUG'].to_s =~ /^(true|t|yes|y|1)$/i
      @logger = @config['logger'] || Logger.new(STDOUT).tap do |logger|
        @api_debug ? logger.level = Logger::DEBUG : logger.level = Logger::INFO
      end
      @connection = ::Faraday.new(@config['uri']) do |conn|
        conn.response :logger, @logger, bodies: true if @api_debug
        conn.request :json
        conn.response :json, :content_type => /\bjson$/
        conn.use AppnexusApi::Faraday::Response::RaiseHttpError
        conn.adapter ::Faraday.default_adapter
      end
    end

    def login
      response = @connection.run_request(
        :post,
        'auth',
        { 'auth' => { 'username' => @config['username'], 'password' => @config['password'] } },
        {}
      )

      if response.body['response']['error_code']
        fail "#{response.body['response']['error_code']}/#{response.body['response']['error_description']}"
      end

      @token = response.body['response']['token']
    end

    def get(route, params={}, headers={})
      params = params.delete_if { |_, v| v.nil? }
      run_request(:get, build_url(route, params), nil, headers)
    end

    def build_url(route, params)
      @connection.build_url(route, params)
    end

    def post(route, body=nil, headers={})
      run_request(:post, route, body, headers)
    end

    def put(route, body=nil, headers={})
      run_request(:put, route, body, headers)
    end

    def delete(route, body=nil, headers={})
      run_request(:delete, route, body, headers)
    end

    def run_request(method, route, body, headers)
      login unless is_authorized?
      response = {}

      Retriable.retriable(on: Unauthorized, on_retry: Proc.new { logout }) do
        Retriable.retriable(on: RateLimitExceeded, on_retry: RATE_LIMIT_WAITER, tries: 10) do
          begin
            response = @connection.run_request(
              method,
              route,
              body,
              { 'Authorization' => @token }.merge(headers)
            )
          rescue ::Faraday::Error::TimeoutError => e
            raise Timeout, e.message, e.message, e.backtrace
          end
        end
      end

      response
    end

    private

    def is_authorized?
      !@token.nil?
    end

    def logout
      @token = nil
    end
  end
end
