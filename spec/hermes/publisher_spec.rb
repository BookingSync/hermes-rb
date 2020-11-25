require "spec_helper"

RSpec.describe Hermes::Publisher do

  before { Hermes.configuration.adapter = :in_memory }

  describe "#reset" do
    subject(:reset) { publisher.reset }

    let(:publisher) { Hermes::Publisher.instance }

    before { publisher.current_adapter }

    it "nillifies @current_adapter instance variable" do
      expect {
        reset
      }.to change { publisher.instance_variable_get("@current_adapter") }.to(nil)
    end
  end

  describe "current_adapter" do
    subject(:current_adapter) { publisher.current_adapter }

    let(:publisher) { Hermes::Publisher.instance }

    it "returns adapter based on the one specified in config" do
      expect(current_adapter).to be_a(Hermes::Publisher::InMemoryAdapter)
    end
  end

  describe "current_adapter=" do
    subject(:override_adapter) { publisher.current_adapter = Hermes::Publisher::HutchAdapter.new }

    let(:publisher) { Hermes::Publisher.instance }

    around do |example|
      VCR.use_cassette("Hermes::Publisher") do
        example.run
      end
    end

    after do
      publisher.reset
    end

    it "overrides current adapter" do
      override_adapter

      expect(publisher.current_adapter).to be_a(Hermes::Publisher::HutchAdapter)
    end
  end
end
