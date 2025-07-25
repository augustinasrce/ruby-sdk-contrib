require "spec_helper"

RSpec.describe OpenFeature::GoFeatureFlag::Evaluators::InProcess do
  subject(:in_process) do
    options = OpenFeature::GoFeatureFlag::Options.new(endpoint: "http://localhost:1031")
    api_client = OpenFeature::GoFeatureFlag::ApiClient.new(options: options)
    described_class.new(api_client: api_client)
  end

  context "#initialize" do
    it 'fetches flags config on init' do
      expect(in_process.flags.size).to eq(13)
    end
  end
end
