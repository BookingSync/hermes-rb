require "spec_helper"

RSpec.describe Hermes::ConsumerBuilder do
  describe ".build" do
    subject(:build) { builder.build(EventClassForTestingConsumerBuilder) }

    let(:builder) { Hermes::ConsumerBuilder.new }

    class EventClassForTestingConsumerBuilder < Hermes::BaseEvent
      def self.routing_key
        "routing_key.for_consumer_test"
      end

      def self.to_s
        "EventClassForTestingConsumerBuilder"
      end

      attribute :bookingsync, Types::Nominal::String
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
    let(:dummy_logger) do
      Class.new do
        attr_reader :log

        def initialize
          @log = ""
        end

        def info(text)
          @log += text
        end
      end.new
    end
    let(:dummy_clock) do
      Class.new do
        def now
          "2020-01-01 12:00:00"
        end
      end.new
    end
    let(:event_handler) { Hermes::EventHandler.new }
    let(:message) do
      Class.new do
        attr_reader :fake_exchange

        def initialize(fake_exchange)
          @fake_exchange = fake_exchange
        end

        def body
          { "bookingsync" => true }
        end

        def properties
          OpenStruct.new(
            reply_to: "bookingsync_queue",
            correlation_id: "bookingsync_123",
            headers: { header: "value" }
          )
        end

        def delivery_info
          OpenStruct.new(
            channel: OpenStruct.new(default_exchange: fake_exchange)
          )
        end
      end.new(fake_exchange)
    end
    let(:fake_exchange) do
      Class.new do
        attr_reader :messages

        def initialize
          @messages = []
        end

        def publish(response, routing_key:, correlation_id:)
          @messages << OpenStruct.new(
            response: response,
            routing_key: routing_key,
            correlation_id: correlation_id
          )
        end
      end.new
    end

    around do |example|
      original_application_prefix = configuration.application_prefix
      original_background_processor = configuration.background_processor
      original_enqueue_method = configuration.enqueue_method
      original_event_handler = configuration.event_handler
      original_logger = Hutch::Logging.logger
      original_clock = configuration.clock

      Hermes.configure do |config|
        config.application_prefix = "app_prefix"
        config.background_processor = background_processor
        config.enqueue_method = :call
        config.event_handler = event_handler
        config.clock = dummy_clock
      end
      Hutch::Logging.logger = dummy_logger

      example.run

      Hermes.configure do |config|
        config.application_prefix = original_application_prefix
        config.background_processor = original_background_processor
        config.enqueue_method = original_enqueue_method
        config.event_handler = original_event_handler
        config.clock = original_clock
      end
      Hutch::Logging.logger = original_logger
    end

    it "builds a Hutch consumer class with a routing key and queue name based on event name" do
      consumer = build

      expect(consumer.get_queue_name).to eq "app_prefix.routing_key.for_consumer_test.queue"
      expect(consumer.routing_keys.to_a).to eq ["routing_key.for_consumer_test"]
    end

    describe "processing" do
      context "when consumer is async (default setting)" do
        before do
          event_handler.handle(EventClassForTestingConsumerBuilder, with: double)
        end

        it "builds a Hutch consumer class that delegates event handling to a background processor and performs logging" do
          consumer = build
          consumer.new.process(message)

          expect(background_processor.store).to eq [
            ["EventClassForTestingConsumerBuilder", { "bookingsync" => true }, { header: "value" }]
          ]
          expect(dummy_logger.log).to eq "[Hutch] enqueued: EventClassForTestingConsumerBuilder with {\"bookingsync\"=>true} at 2020-01-01 12:00:00"

        end

        it "is instrumented" do
          expect(configuration.instrumenter).to receive(:instrument).with("Hermes.Consumer.process")

          consumer = build
          consumer.new.process(message)
        end
      end

      context "when consumer is sync" do
        let(:handler) do
          Class.new do
            attr_reader :event

            def call(event)
              @event = event
              {
                processed: true
              }
            end
          end.new
        end

        context "without RPC" do
          before do
            event_handler.handle(EventClassForTestingConsumerBuilder, with: handler, async: false)
          end

          it "builds a Hutch consumer class that directly calls the event handler and does not handle RPC" do
            consumer = build
            expect {
              consumer.new.process(message)
            }.not_to change { fake_exchange.messages.count }

            expect(handler.event).to be_instance_of(EventClassForTestingConsumerBuilder)
            expect(handler.event.bookingsync).to eq true
            expect(handler.event.origin_body).to eq("bookingsync" => true)
            expect(handler.event.origin_headers).to eq(header: "value")
          end

          it "is instrumented" do
            expect(configuration.instrumenter).to receive(:instrument).with("Hermes.Consumer.process")

            consumer = build
            consumer.new.process(message)
          end
        end

        context "with RPC" do
          before do
            event_handler.handle(EventClassForTestingConsumerBuilder, with: handler, async: false, rpc: true)
          end

          it "builds a Hutch consumer class that directly calls the event handler and replies back
          handling RPC call" do
            consumer = build
            expect {
              consumer.new.process(message)
            }.to change { fake_exchange.messages.count }.by(1)

            expect(handler.event).to be_instance_of(EventClassForTestingConsumerBuilder)
            expect(handler.event.bookingsync).to eq(true)
            expect(handler.event.origin_body).to eq("bookingsync" => true)
            expect(handler.event.origin_headers).to eq(header: "value")
            expect(fake_exchange.messages.first.response).to eq("{\"processed\":true}")
            expect(fake_exchange.messages.first.routing_key).to eq("bookingsync_queue")
            expect(fake_exchange.messages.first.correlation_id).to eq("bookingsync_123")
          end

          it "is instrumented" do
            expect(configuration.instrumenter).to receive(:instrument).with("Hermes.Consumer.process")

            consumer = build
            consumer.new.process(message)
          end
        end
      end
    end

    it "registers a class under a constant derived from event name and HutchConsumer suffix" do
      consumer = build

      expect(consumer).to eq EventClassForTestingConsumerBuilderHutchConsumer
    end
  end
end
