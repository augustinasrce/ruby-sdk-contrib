# frozen_string_literal: true

require "net/http"
require "faraday"
require_relative "error/errors"

module OpenFeature
  module GoFeatureFlag
    class ApiClient
      attr_accessor :retry_after

      def initialize(options: {})
        @options = options
        @retry_after = nil
        @faraday_connection = Faraday.new(
          url: @options.endpoint,
          headers: { "Content-Type" => "application/json" }.merge(@options.custom_headers || {})
        )
      end

      def ofrep_evaluate(flag_key, evaluation_context)
        rate_limiter

        @faraday_connection.post("/ofrep/v1/evaluate/flags/#{flag_key}") do |req|
          req.body = { context: evaluation_context.fields }.to_json
        end
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
    end
  end
end
