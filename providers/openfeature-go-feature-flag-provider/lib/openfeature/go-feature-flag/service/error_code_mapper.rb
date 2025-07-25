# frozen_string_literal: true

module OpenFeature
  module GoFeatureFlag
    class ErrorCodeMapper < ::Service
      ERROR_CODE_MAP = {
        "PROVIDER_NOT_READY" => SDK::Provider::ErrorCode::PROVIDER_NOT_READY,
        "FLAG_NOT_FOUND" => SDK::Provider::ErrorCode::FLAG_NOT_FOUND,
        "PARSE_ERROR" => SDK::Provider::ErrorCode::PARSE_ERROR,
        "TYPE_MISMATCH" => SDK::Provider::ErrorCode::TYPE_MISMATCH,
        "TARGETING_KEY_MISSING" => SDK::Provider::ErrorCode::TARGETING_KEY_MISSING,
        "INVALID_CONTEXT" => SDK::Provider::ErrorCode::INVALID_CONTEXT,
        "GENERAL" => SDK::Provider::ErrorCode::GENERAL
      }

      def initialize(error_code_str:)
        @error_code_str = error_code_str.upcase
      end

      def run
        ERROR_CODE_MAP[@error_code_str] || SDK::Provider::ErrorCode::GENERAL
      end
    end
  end
end

