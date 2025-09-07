# frozen_string_literal: true

require "net/http"
require "faraday"
require "faraday/net_http_persistent"
require_relative "error/errors"

module OpenFeature
  module GoFeatureFlag
    class ApiClient
      attr_accessor :retry_after

      def initialize(options: Options.new)
        @options = options
        @retry_after = nil
        @faraday_connection = Faraday.new(
          url: @options.endpoint,
          headers: {"Content-Type" => "application/json"}.merge(@options.custom_headers || {})
        ) do |f|
          f.adapter :net_http_persistent do |http|
            http.idle_timeout = 30
          end
        end
      end

      def ofrep_evaluate(flag_key, evaluation_context)
        rate_limiter

        @faraday_connection.post("/ofrep/v1/evaluate/flags/#{flag_key}") do |req|
          req.body = {context: evaluation_context.fields}.to_json
        end
      end

      def fetch_flags_configuration(flags: nil, etag: nil)
        rate_limiter

        response = @faraday_connection.post("/v1/flag/configuration") do |req|
          req.body = { flags: flags }.to_json unless flags.nil?
          req.headers['If-None-Match'] = etag unless etag.nil?
        end

        handle_configuration_response(response)
      end

      private

      def rate_limiter
        unless @retry_after.nil?
          if Time.now < @retry_after
            raise OpenFeature::GoFeatureFlag::Errors::RateLimited.new(nil)
          else
            @retry_after = nil
          end
        end
      end

      def handle_evaluation_response(response, flag_key)
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

      def handle_configuration_response(response)
        case response.status
        when 200, 304
          FlagsConfigurationApiResponse.new(response)
        when 401, 403
          raise Errors::UnauthorizedError.new(response)
        when 404
          raise Errors::FlagConfigurationNotFoundError.new(response)
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
