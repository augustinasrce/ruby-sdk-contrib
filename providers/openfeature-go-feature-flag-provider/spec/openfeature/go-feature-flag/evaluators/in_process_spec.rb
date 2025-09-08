require "spec_helper"

RSpec.describe OpenFeature::GoFeatureFlag::Evaluators::InProcess do
  subject(:in_process) do
    options = OpenFeature::GoFeatureFlag::Options.new(endpoint: "http://localhost:1031")
    api_client = OpenFeature::GoFeatureFlag::ApiClient.new(options: options)
    described_class.new(api_client: api_client)
  end

  context "#initialize" do
    let (:time) { Time.parse("2025-09-08 18:59:22.000000000 +0000") }

    it "fetches flags config on init" do
      stub_request(:post, "http://localhost:1031/v1/flag/configuration")
        .to_return(status: 200, body:
          {
            flags: {
              bool_flag: {
                variations: {false => false, true => true},
                defaultRule: {variation: "true"}
              }
            }
          }.to_json, headers: {:etag => "test-etag-value", "last-modified" => time.httpdate})

      expect(in_process.flags.size).to eq(1)
      expect(in_process.etag).to eq("test-etag-value")
      expect(in_process.last_modified).to eq(time)
    end
  end
end
