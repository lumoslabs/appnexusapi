module AppnexusApi
  module Faraday
    module Response
      class RaiseHttpError < ::Faraday::Response::Middleware
        # Inexplicably, sandbox uses the correct code of 429, while production uses 405? so
        # we just rely on the error message
        RATE_EXCEEDED_ERROR = 'RATE_EXCEEDED'.freeze

        def on_complete(response)
          case response[:status].to_i
          when 400
            raise AppnexusApi::BadRequest, error_message(response)
          when 401
            raise AppnexusApi::Unauthorized, error_message(response)
          when 403
            raise AppnexusApi::Forbidden, error_message(response)
          when 404
            raise AppnexusApi::NotFound, error_message(response)
          when 406
            raise AppnexusApi::NotAcceptable, error_message(response)
          when 422
            raise AppnexusApi::UnprocessableEntity, error_message(response)
          when 500
            raise AppnexusApi::InternalServerError, error_message(response)
          when 501
            raise AppnexusApi::NotImplemented, error_message(response)
          when 502
            raise AppnexusApi::BadGateway, error_message(response)
          when 503
            raise AppnexusApi::ServiceUnavailable, error_message(response)
          end
          puts "before"
          return if response.body.empty?
          puts "response body: #{JSON.parse(response.body).fetch('response', {})}"
          if JSON.parse(response.body).fetch('response', {})['error_code'] == RATE_EXCEEDED_ERROR
            puts "Matched error!"
            raise AppnexusApi::RateLimitExceeded, "Retry after #{response.response_headers['retry-after']}s"
          end
        end

        def error_message(response)
          msg = "#{response[:method].to_s.upcase} #{response[:url].to_s}: #{response[:status]}"
          if (errors = response[:body]) && response[:body]['errors']
            msg << "\n"
            msg << errors.join("\n")
          end
          msg
        end
      end
    end
  end
end
