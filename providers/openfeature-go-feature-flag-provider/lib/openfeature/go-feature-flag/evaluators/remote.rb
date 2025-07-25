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

          OpenFeature::GoFeatureFlag::OfrepApiResponse.new(
            value: json["value"],
            key: json["key"],
            reason: reason_mapper(json["reason"]),
            variant: json["variant"],
            error_code: nil,
            error_details: nil,
            metadata: json["metadata"]
          )
        end

        def parse_error_response(json)
          validate_response(json, %w[key error_code])

          OpenFeature::GoFeatureFlag::OfrepApiResponse.new(
            value: nil,
            key: json["key"],
            reason: SDK::Provider::Reason::ERROR,
            variant: nil,
            error_code: error_code_mapper(json["error_code"]),
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

        def reason_mapper(reason_str)
          reason_str = reason_str.upcase
          reason_map = {
            "STATIC" => SDK::Provider::Reason::STATIC,
            "DEFAULT" => SDK::Provider::Reason::DEFAULT,
            "TARGETING_MATCH" => SDK::Provider::Reason::TARGETING_MATCH,
            "SPLIT" => SDK::Provider::Reason::SPLIT,
            "CACHED" => SDK::Provider::Reason::CACHED,
            "DISABLED" => SDK::Provider::Reason::DISABLED,
            "UNKNOWN" => SDK::Provider::Reason::UNKNOWN,
            "STALE" => SDK::Provider::Reason::STALE,
            "ERROR" => SDK::Provider::Reason::ERROR
          }
          reason_map[reason_str] || SDK::Provider::Reason::UNKNOWN
        end

        def error_code_mapper(error_code_str)
          error_code_str = error_code_str.upcase
          error_code_map = {
            "PROVIDER_NOT_READY" => SDK::Provider::ErrorCode::PROVIDER_NOT_READY,
            "FLAG_NOT_FOUND" => SDK::Provider::ErrorCode::FLAG_NOT_FOUND,
            "PARSE_ERROR" => SDK::Provider::ErrorCode::PARSE_ERROR,
            "TYPE_MISMATCH" => SDK::Provider::ErrorCode::TYPE_MISMATCH,
            "TARGETING_KEY_MISSING" => SDK::Provider::ErrorCode::TARGETING_KEY_MISSING,
            "INVALID_CONTEXT" => SDK::Provider::ErrorCode::INVALID_CONTEXT,
            "GENERAL" => SDK::Provider::ErrorCode::GENERAL
          }
          error_code_map[error_code_str] || SDK::Provider::ErrorCode::GENERAL
        end
      end
    end
  end
end
