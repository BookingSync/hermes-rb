require "spec_helper"

RSpec.describe Hermes::EventHandler, :freeze_time, :with_application_prefix do
  describe "event handling" do
    subject(:event_handler) { Hermes::EventHandler.new }

    class EventClassForTestingEventHandler < Hermes::BaseEvent
      def self.routing_key
        "routing_key.for_event_handler_test"
      end
    end
    class EventClassForTestingSynchronousEventHandler < Hermes::BaseEvent
      def self.routing_key
        # add extra suffix in case Rabbit complains about "precondition failed" when a queue was registered with different config
        "routing_key.for_event_handler_test_synchronous_#{Time.now.to_i}"
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
          async: false, rpc: true, consumer_config: -> { arguments "x-max-length" => 10 }
      end
    end

    around do |example|
      original_background_processor = configuration.background_processor
      original_enqueue_method = configuration.enqueue_method
      original_event_handler = configuration.event_handler

      Hermes.configure do |config|
        config.background_processor = background_processor
        config.enqueue_method = :call
        config.event_handler = event_handler
      end

      example.run

      Hermes.configure do |config|
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
      expect(registration.consumer.get_arguments).to eq({})
      expect(registration.options).to include(async: true, rpc: false)
      expect(registration.options.keys).to match_array [:async, :rpc, :consumer_config]

      registration = event_handler.registration_for(EventClassForTestingSynchronousEventHandler)

      expect(registration.handler).to eq HandlerForSynchronousEventClassForTestingEventHandler
      expect(registration.consumer).to eq EventClassForTestingSynchronousEventHandlerHutchConsumer

      expect(registration.options).to include(async: false, rpc: true)
      expect(registration.options.keys).to match_array [:async, :rpc, :consumer_config]
    end


    describe "building consumer" do
      subject(:consume_with_consumer_without_extra_options) do
        consumer_without_extra_options.new.process(message)
      end
      subject(:consumer_with_extra_options) do
        event_handler.registration_for(EventClassForTestingSynchronousEventHandler).consumer
      end
      let(:consumer_without_extra_options) do
        event_handler.registration_for(EventClassForTestingEventHandler).consumer
      end

      it "registers HutchConsumer under :consumer inside registration respecting consumer_config" do
        expect(consumer_without_extra_options.routing_keys.to_a).to eq ["routing_key.for_event_handler_test"]
        expect(consumer_without_extra_options.get_queue_name).to eq "app_prefix.routing_key.for_event_handler_test.queue"
        expect(consumer_without_extra_options.get_arguments).to eq({})

        expect(consumer_with_extra_options.get_arguments).to eq("x-max-length" => 10)
      end

      it "the register consumer that actually works" do
        expect {
          consume_with_consumer_without_extra_options
        }.to change { background_processor.store }.from([]).to([
          ["EventClassForTestingEventHandler", { "bookingsync" => true }, { "example" => "value" } ]
        ])
      end
    end
  end

  describe "#handle" do
    subject(:handle) do
      event_handler.handle(EventClassForTestingEventHandler, with: HandlerForEventClassForTestingEventHandler,
        consumer_config: -> { arguments "x-max-length" => 10 })
    end

    let(:event_handler) { described_class.new }

    it "returns Registration containing handler, consumer and options" do
      expect(handle.handler).to eq HandlerForEventClassForTestingEventHandler
      expect(handle.consumer).to eq EventClassForTestingEventHandlerHutchConsumer
      expect(handle.options).to include(async: true, rpc: false)
      expect(handle.options.keys).to match_array [:async, :rpc, :consumer_config]
    end
  end
end
