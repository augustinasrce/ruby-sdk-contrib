# frozen_string_literal: true

require "open_feature/sdk"
require "net/http"
require "json"
require "faraday"
require_relative "../error/errors"
require_relative "../model/ofrep_api_response"

module OpenFeature
  module GoFeatureFlag
    module Evaluators
      class Remote

        def initialize(api_client:)
          @api_client = api_client
        end

        def evaluate(flag_key:, evaluation_context:)
          response = @api_client.ofrep_evaluate(flag_key, evaluation_context)
          handle_response(response, flag_key)
        end

        private

        def handle_response(response, flag_key)
          case response.status
          when 200
            parse_success_response(JSON.parse(response.body))
          when 400
            parse_error_response(JSON.parse(response.body))
          when 401, 403
            raise Errors::UnauthorizedError.new(response)
          when 404
            raise Errors::FlagNotFoundError.new(response, flag_key)
          when 429
            parse_retry_later_header(response)
            raise Errors::RateLimited.new(response)
          else
            raise Errors::InternalServerError.new(response)
          end
        end

        def validate_response(json, required_keys)
          missing_keys = required_keys - json.keys
          unless missing_keys.empty?
            raise Errors::ParseError.new(json)
          end
        end

        def parse_success_response(json)
          validate_response(json, %w[key value reason variant])

          OfrepApiResponse.new(
            value: json["value"],
            key: json["key"],
            reason: ReasonMapper.run(reason_str: json["reason"]),
            variant: json["variant"],
            error_code: nil,
            error_details: nil,
            metadata: json["metadata"]
          )
        end

        def parse_error_response(json)
          validate_response(json, %w[key error_code])

          OfrepApiResponse.new(
            value: nil,
            key: json["key"],
            reason: SDK::Provider::Reason::ERROR,
            variant: nil,
            error_code: ErrorCodeMapper.run(error_code_str: json["error_code"]),
            error_details: json["error_details"],
            metadata: nil
          )
        end

        def parse_retry_later_header(response)
          retry_after = response["Retry-After"]
          return nil if retry_after.nil?

          begin
            @api_client.retry_after = if /^\d+$/.match?(retry_after)
                                    # Retry-After is in seconds
                                    Time.now + Integer(retry_after)
                                  else
                                    # Retry-After is an HTTP-date
                                    Time.httpdate(retry_after)
                                  end
          rescue ArgumentError
            # ignore invalid Retry-After header
            nil
          end
        end
      end
    end
  end
end
