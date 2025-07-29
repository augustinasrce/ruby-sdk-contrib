require "spec_helper"

RSpec.describe OpenFeature::GoFeatureFlag::FlagsConfigurationApiResponse do
  subject do
    described_class.new(response)
  end

  context "#initialize with faulty json" do
    let(:headers) { Faraday::Utils::Headers.new }
    let!(:response) do
      Faraday::Response.new(Faraday::Env.new(:post, "", nil, Faraday::RequestOptions.new,
                                             Faraday::Utils::Headers.new, Faraday::SSLOptions, nil, nil,
                                             Faraday::Response.new, headers, 200, "OK", "asd{{"))
    end

    it "raises exception" do
      expect { subject }.to raise_error(OpenFeature::GoFeatureFlag::Errors::ImpossibleToRetrieveConfiguration)
    end
  end
end
