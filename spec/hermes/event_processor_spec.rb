require "spec_helper"

RSpec.describe Hermes::EventProcessor do
  describe ".call" do
    subject(:call) { described_class.call(EventClassForTestingAsyncMessagingEventProcessor.to_s, payload) }

    let(:configuration) { Hermes.configuration }
    let(:event_handler) { Hermes::EventHandler.new }
    class EventClassForTestingAsyncMessagingEventProcessor
      attr_reader :bookingsync

      def initialize(bookingsync: )
        @bookingsync = bookingsync
      end

      def self.routing_key
        to_s.split("::")[1..-1].map(&:underscore).map(&:downcase).join(".")
      end

      def routing_key
        self.class.routing_key
      end
    end
    class HandlerForEventClassForTestingAsyncMessagingEventProcessor
      def self.event
        @event
      end

      def self.call(event)
        @event = event
      end
    end
    let(:payload) do
      {
        "bookingsync" => {
          "rabbit" => true
        }
      }
    end

    before do
      event_handler.handle_events do
        handle EventClassForTestingAsyncMessagingEventProcessor, with: HandlerForEventClassForTestingAsyncMessagingEventProcessor
      end
    end

    around do |example|
      original_event_handler = configuration.event_handler

      Hermes.configure do |config|
        config.event_handler = event_handler
      end

      example.run

      Hermes.configure do |config|
        config.event_handler = original_event_handler
      end
    end

    it "calls proper handler with a given event, performing deep symbolization on keys" do
      call

      expect(HandlerForEventClassForTestingAsyncMessagingEventProcessor.event).to be_a(EventClassForTestingAsyncMessagingEventProcessor)
      expect(HandlerForEventClassForTestingAsyncMessagingEventProcessor.event.bookingsync).to eq(rabbit: true)
    end

    it "is instrumented" do
      expect(Hermes.configuration.instrumenter).to receive(:instrument)
        .with("Hermes.EventProcessor.EventClassForTestingAsyncMessagingEventProcessor")
        .and_call_original

      call
    end
  end
end
