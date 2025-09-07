# frozen_string_literal: true

module OpenFeature
  module GoFeatureFlag
    module Evaluators
      class InProcess
        attr_reader :api_client
        attr_accessor :flags, :etag, :last_modified

        def initialize(api_client:)
          @api_client = api_client
          response = handle_response(@api_client.fetch_flags_configuration)
          @flags = response.flags
          @etag = response.etag
          @last_modified = response.last_modified
        end

        def evaluate(flag_key:, evaluation_context:)
          true
        end
      end
    end
  end
end
