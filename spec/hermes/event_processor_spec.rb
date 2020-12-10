require "spec_helper"

RSpec.describe Hermes::EventProcessor, :with_application_prefix do
  describe ".call" do
    subject(:call) { described_class.call(EventClassForTestingAsyncMessagingEventProcessor.to_s, body, headers) }

    let(:configuration) { Hermes.configuration }
    let(:event_handler) { Hermes::EventHandler.new }
    class EventClassForTestingAsyncMessagingEventProcessor < Hermes::BaseEvent
      attribute :bookingsync, Types::Nominal::Hash
    end
    class HandlerForEventClassForTestingAsyncMessagingEventProcessor
      def self.event
        @event
      end

      def self.call(event)
        @event = event
        "response"
      end
    end
    let(:body) do
      {
        "bookingsync" => {
          "rabbit" => true
        }
      }
    end
    let(:headers) do
      {
        header: "value"
      }
    end

    before do
      event_handler.handle_events do
        handle EventClassForTestingAsyncMessagingEventProcessor, with: HandlerForEventClassForTestingAsyncMessagingEventProcessor
      end
    end

    around do |example|
      original_event_handler = configuration.event_handler
      original_distributed_tracing_database_uri = configuration.distributed_tracing_database_uri

      Hermes.configure do |config|
        config.event_handler = event_handler
        config.distributed_tracing_database_uri = ENV["DISTRIBUTED_TRACING_DATABASE_URI"]
      end

      example.run

      Hermes.configure do |config|
        config.event_handler = original_event_handler
        config.distributed_tracing_database_uri = original_distributed_tracing_database_uri
      end
    end

    it "calls proper handler with a given event, performing deep symbolization on keys" do
      call

      expect(HandlerForEventClassForTestingAsyncMessagingEventProcessor.event).to be_a(EventClassForTestingAsyncMessagingEventProcessor)
      expect(HandlerForEventClassForTestingAsyncMessagingEventProcessor.event.origin_body).to eq("bookingsync" => { "rabbit" => true } )
      expect(HandlerForEventClassForTestingAsyncMessagingEventProcessor.event.origin_headers).to eq(header: "value")
      expect(HandlerForEventClassForTestingAsyncMessagingEventProcessor.event.bookingsync).to eq(rabbit: true)
    end

    it "is instrumented" do
      expect(Hermes.configuration.instrumenter).to receive(:instrument)
        .with("Hermes.EventProcessor.EventClassForTestingAsyncMessagingEventProcessor")
        .and_call_original

      call
    end

    it "returns result response from the event handler and the event" do
      expect(call.response).to eq "response"
      expect(call.event).to be_instance_of(EventClassForTestingAsyncMessagingEventProcessor)
    end

    it "stores distributed trace" do
      expect {
        call
      }.to change { Hermes::DistributedTrace.count }.by(1)

      expect(Hermes::DistributedTrace.last.event_class).to eq "EventClassForTestingAsyncMessagingEventProcessor"
    end

    it "assigns origin headers to Hermes" do
      expect {
        call
      }.to change { Hermes.origin_headers }.from({}).to(headers)
    end
  end
end
