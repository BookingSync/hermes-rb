require "spec_helper"

RSpec.describe Hermes do
  it "has a version number" do
    expect(Hermes::Rb::VERSION).not_to be_nil
  end

  describe ".configure" do
    subject(:configuration) { Hermes.configuration }

    let(:adapter) { "bookingsync" }
    let(:hutch_uri) { "#DisciplineEqualsFreedom" }
    let(:application_prefix) { "bookingsync_prefix" }
    let(:background_processor ) { Object }
    let(:enqueue_method ) { :new }
    let(:event_handler ) { "Rich Piana" }

    around do |example|
      original_adapter = configuration.adapter
      original_application_prefix = configuration.application_prefix
      original_background_processor = configuration.background_processor
      original_enqueue_method = configuration.enqueue_method
      original_event_handler = configuration.event_handler
      original_hutch_uri = configuration.hutch.uri

      Hermes.configure do |config|
        config.adapter = adapter
        config.application_prefix = application_prefix
        config.background_processor = background_processor
        config.enqueue_method = enqueue_method
        config.event_handler = event_handler
        config.configure_hutch do |hutch|
          hutch.uri = hutch_uri
        end
      end

      example.run

      Hermes.configure do |config|
        config.adapter = original_adapter
        config.application_prefix = original_application_prefix
        config.background_processor = original_background_processor
        config.enqueue_method = original_enqueue_method
        config.event_handler = original_event_handler
        config.configure_hutch do |hutch|
          hutch.uri = original_hutch_uri
        end
      end
    end

    it "is configurable" do
      expect(configuration.adapter).to eq adapter
      expect(configuration.hutch.uri).to eq hutch_uri
    end
  end

  describe "origin_headers" do
    subject(:assign_origin_headers) { described_class.origin_headers = headers }

    let(:headers) do
      {
        header: "value"
      }
    end

    it { is_expected_block.to change { described_class.origin_headers }.from({}).to(headers) }
  end

  describe ".with_origin_headers" do
    subject(:with_origin_headers) { described_class.with_origin_headers(headers) { "value" } }

    let(:headers) do
      {
        header: "value"
      }
    end

    before do
      allow(Hermes).to receive(:origin_headers=).and_call_original
      allow(Hermes).to receive(:clear_origin_headers).and_call_original
    end

    it "temporarily assigns origin_headers and returns original value" do
      expect(with_origin_headers).to eq "value"

      expect(Hermes).to have_received(:origin_headers=).with(headers)
      expect(Hermes).to have_received(:clear_origin_headers)
    end
  end

  describe ".clear_origin_headers" do
    subject(:clear_origin_headers) { described_class.clear_origin_headers }

    let(:headers) do
      {
        header: "value"
      }
    end

    before do
      described_class.origin_headers = headers
    end

    it { is_expected_block.to change { described_class.origin_headers }.from(headers).to({}) }
  end
end
