require 'faraday_middleware'
require 'appnexusapi/faraday/raise_http_error'

class AppnexusApi::Connection
  # Inexplicably, sandbox uses the correct code of 429, while production uses 405? so
  # we just rely on the error message
  RATE_EXCEEDED_ERROR = 'RATE_EXCEEDED'.freeze
  RATE_EXCEEDED_DEFAULT_TIMEOUT = 15

  attr_reader :logger

  def initialize(config)
    @config = config
    @config['uri'] ||= 'https://api.appnexus.com/'
    @logger = @config['logger'] || Logger.new(STDOUT)
    @connection = Faraday.new(@config['uri']) do |conn|
      conn.response :logger, @logger, bodies: true
      conn.request :json
      conn.response :json, :content_type => /\bjson$/

      conn.use AppnexusApi::Faraday::Response::RaiseHttpError
      conn.adapter Faraday.default_adapter
    end
  end

  def is_authorized?
    !@token.nil?
  end

  def login
    response = @connection.run_request(:post, 'auth', { 'auth' => { 'username' => @config['username'], 'password' => @config['password'] } }, {})
    if response.body['response']['error_code']
      fail "#{response.body['response']['error_code']}/#{response.body['response']['error_description']}"
    end

    @token = response.body['response']['token']
  end

  def logout
    @token = nil
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

    rate_limit_sleep = Proc.new do |exception, try, elapsed_time, next_interval|
      seconds = /Retry after \d+s/.match(exception.message)[1]
      @logger.info("Sleeping for #{seconds}s...")
      sleep seconds
    end

    Retriable.retriable(on: Unauthorized, on_retry: Proc.new { logout }) do
      Retriable.retriable(on: RateLimitExceeded, on_retry: rate_limit_sleep) do
        begin
          response = run_request_only(
            method,
            route,
            body,
            { 'Authorization' => @token }.merge(headers)
          )
        rescue Faraday::Error::TimeoutError
          raise AppnexusApi::Timeout, 'Timeout'
        end
      end
    end

    response
  end

  def run_request_only(method, route, body, headers)
    @connection.run_request(
      method,
      route,
      body,
      { 'Authorization' => @token }.merge(headers)
    )
  end
end
