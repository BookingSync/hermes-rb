require "spec_helper"

RSpec.describe Hermes::EventHandler do
  describe "event handling" do
    subject(:event_handler) { Hermes::EventHandler.new }

    class EventClassForTestingEventHandler < Hermes::BaseEvent
      def self.routing_key
        "routing_key.for_event_handler_test"
      end
    end
    class EventClassForTestingSynchronousEventHandler < Hermes::BaseEvent
      def self.routing_key
        "routing_key.for_event_handler_test_synchronous"
      end
    end

    let(:configuration) { Hermes.configuration }
    let(:background_processor) do
      Class.new do
        attr_reader :store

        def initialize
          @store = []
        end

        def call(event, body, headers)
          store << [event, body, headers]
        end
      end.new
    end
    let(:clock) do
      Class.new do
        def now
          Time.new(2018, 1, 1, 12, 0, 0, 0)
        end
      end.new
    end
    class HandlerForEventClassForTestingEventHandler
    end
    class HandlerForSynchronousEventClassForTestingEventHandler
    end
    let(:message) do
      double(:message, body: { "bookingsync" => true }, properties: { headers: { "example" => "value" } })
    end

    before do
      Hermes.configuration.clock = clock
      event_handler.handle_events do
        handle EventClassForTestingEventHandler, with: HandlerForEventClassForTestingEventHandler
        handle EventClassForTestingSynchronousEventHandler, with: HandlerForSynchronousEventClassForTestingEventHandler,
          async: false, rpc: true
      end
    end

    around do |example|
      original_application_prefix = configuration.application_prefix
      original_background_processor = configuration.background_processor
      original_enqueue_method = configuration.enqueue_method
      original_event_handler = configuration.event_handler

      Hermes.configure do |config|
        config.application_prefix = "app_prefix"
        config.background_processor = background_processor
        config.enqueue_method = :call
        config.event_handler = event_handler
      end

      example.run

      Hermes.configure do |config|
        config.application_prefix = original_application_prefix
        config.background_processor = original_background_processor
        config.enqueue_method = original_enqueue_method
        config.event_handler = original_event_handler
      end
    end

    it "allows to register events using handle_events/handle methods and the result of them can be fetched
    using registration_for" do
      registration = event_handler.registration_for(EventClassForTestingEventHandler)

      expect(registration.handler).to eq HandlerForEventClassForTestingEventHandler
      expect(registration.consumer).to eq EventClassForTestingEventHandlerHutchConsumer
      expect(registration.options).to eq(async: true, rpc: false)

      registration = event_handler.registration_for(EventClassForTestingSynchronousEventHandler)

      expect(registration.handler).to eq HandlerForSynchronousEventClassForTestingEventHandler
      expect(registration.consumer).to eq EventClassForTestingSynchronousEventHandlerHutchConsumer
      expect(registration.options).to eq(async: false, rpc: true)
    end

    it "registers HutchConsumer under :consumer inside registration" do
      consumer = event_handler.registration_for(EventClassForTestingEventHandler).consumer

      expect(consumer.routing_keys.to_a).to eq ["routing_key.for_event_handler_test"]
      expect(consumer.get_queue_name).to eq "app_prefix.routing_key.for_event_handler_test.queue"

      consumer.new.process(message)

      expect(background_processor.store).to eq [
        ["EventClassForTestingEventHandler", { "bookingsync" => true }, { "example" => "value" } ]
      ]
    end
  end
end
