# frozen_string_literal: true

module OpenFeature
  module GoFeatureFlag
    module Evaluators
      class InProcess
        attr_accessor :flags

        def initialize(flags)
          @flags = flags
        end

      end
    end
  end
end
