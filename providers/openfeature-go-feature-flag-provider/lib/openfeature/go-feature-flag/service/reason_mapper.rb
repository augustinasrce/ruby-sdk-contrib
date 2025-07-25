# frozen_string_literal: true

module OpenFeature
  module GoFeatureFlag
    class ReasonMapper < ::Service
      REASON_MAP = {
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

      def initialize(reason_str:)
        @reason_str = reason_str.upcase
      end

      def run
        REASON_MAP[@reason_str] || SDK::Provider::Reason::UNKNOWN
      end
    end
  end
end

