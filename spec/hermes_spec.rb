require "spec_helper"

RSpec.describe:Hermes do
  it "has a version number" do
    expect(Hermes::Rb::VERSION).not_to be_nil
  end

  describe ".configure" do
    subject(:configuration) { Hermes.configuration }

    let(:adapter) { "bookingsync" }
    let(:correlation_uuid_generator) { "RabbitMQ FTW" }
    let(:hutch_uri) { "#DisciplineEqualsFreedom" }
    let(:application_prefix) { "bookingsync_prefix" }
    let(:background_processor ) { Object }
    let(:enqueue_method ) { :new }
    let(:event_handler ) { "Rich Piana" }

    around do |example|
      original_adapter = configuration.adapter
      original_correlation_uuid_generator = configuration.correlation_uuid_generator
      original_application_prefix = configuration.application_prefix
      original_background_processor = configuration.background_processor
      original_enqueue_method = configuration.enqueue_method
      original_event_handler = configuration.event_handler
      original_hutch_uri = configuration.hutch.uri

      Hermes.configure do |config|
        config.adapter = adapter
        config.correlation_uuid_generator = correlation_uuid_generator
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
        config.correlation_uuid_generator = original_correlation_uuid_generator
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
      expect(configuration.correlation_uuid_generator).to eq correlation_uuid_generator
      expect(configuration.hutch.uri).to eq hutch_uri
    end
  end
end
