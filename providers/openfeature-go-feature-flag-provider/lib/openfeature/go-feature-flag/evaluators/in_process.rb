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

        private

        def handle_response(response)
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
