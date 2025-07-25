module OpenFeature
  module GoFeatureFlag
    class FlagsConfigurationApiResponse
      attr_reader :flags, :etag, :last_modified, :evaluation_context_enrichment

      def initialize(response)
        @etag = parse_etag_header(response)
        @last_modified = parse_last_modified_header(response)
        body = JSON.parse(response.body)
        @flags = body['flags']
        @evaluation_context_enrichment = body['evaluationContextEnrichment']
      end

      private

      def parse_etag_header(response)
        etag = response["Etag"]
        return nil if etag.nil?

        @etag = etag
      end

      def parse_last_modified_header(response)
        str = response['Last-Modified']
        @last_modified = Time.parse(str) unless str.nil?
      end
    end
  end
end
