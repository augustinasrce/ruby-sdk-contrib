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
          @api_client.ofrep_evaluate(flag_key, evaluation_context)
        end
      end
    end
  end
end
