require "spec_helper"

RSpec.describe Hermes::ConsumerBuilder, :freeze_time do
  describe ".build" do
    subject(:build) { builder.build(EventClassForTestingConsumerBuilder) }

    let(:builder) { Hermes::ConsumerBuilder.new }

    class EventClassForTestingConsumerBuilder < Hermes::BaseEvent
      def self.routing_key
        # add extra suffix in case Rabbit complains about "precondition failed" when a queue was registered with different config
        "routing_key.for_consumer_test_#{Time.now.to_i}"
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

        def publish(response, routing_key:, correlation_id:, headers:)
          @messages << OpenStruct.new(
            response: response,
            routing_key: routing_key,
            correlation_id: correlation_id,
            headers: headers
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
      original_distributed_tracing_database_uri = configuration.distributed_tracing_database_uri
      original_database_connection_provider = configuration.database_connection_provider

      Hermes.configure do |config|
        config.application_prefix = "app_prefix"
        config.background_processor = background_processor
        config.enqueue_method = :call
        config.event_handler = event_handler
        config.clock = dummy_clock
        config.distributed_tracing_database_uri = ENV["DISTRIBUTED_TRACING_DATABASE_URI"]
        config.database_connection_provider = ActiveRecord::Base
      end
      Hutch::Logging.logger = dummy_logger

      example.run

      Hermes.configure do |config|
        config.application_prefix = original_application_prefix
        config.background_processor = original_background_processor
        config.enqueue_method = original_enqueue_method
        config.event_handler = original_event_handler
        config.clock = original_clock
        config.distributed_tracing_database_uri = original_distributed_tracing_database_uri
        config.database_connection_provider = original_database_connection_provider
      end
      Hutch::Logging.logger = original_logger
    end

    it "builds a Hutch consumer class with a routing key and queue name based on event name" do
      consumer = build

      expect(consumer.get_queue_name).to eq "app_prefix.routing_key.for_consumer_test_#{Time.now.to_i}.queue"
      expect(consumer.routing_keys.to_a).to eq ["routing_key.for_consumer_test_#{Time.now.to_i}"]
    end

    describe "processing" do
      subject(:process) { consumer.new.process(message) }

      let(:consumer) { build }

      context "when consumer is async (default setting)" do
        before do
          event_handler.handle(EventClassForTestingConsumerBuilder, with: double)
        end

        it "builds a Hutch consumer class that delegates event handling to a background processor and performs logging" do
          process

          expect(background_processor.store).to eq [
            ["EventClassForTestingConsumerBuilder", { "bookingsync" => true }, { header: "value" }]
          ]
          expect(dummy_logger.log).to eq "[Hutch] enqueued: EventClassForTestingConsumerBuilder, headers: {:header=>\"value\"}, body: {\"bookingsync\"=>true} at 2020-01-01 12:00:00"

        end

        it "is instrumented" do
          expect(configuration.instrumenter).to receive(:instrument).with("Hermes.Consumer.process")

          process
        end

        it "does not create any traces (because the event is enqueued for processing, not being processed)" do
          expect {
            process
          }.not_to change { Hermes::DistributedTrace.count }
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
            expect {
              process
            }.not_to change { fake_exchange.messages.count }

            expect(handler.event).to be_instance_of(EventClassForTestingConsumerBuilder)
            expect(handler.event.bookingsync).to eq true
            expect(handler.event.origin_body).to eq("bookingsync" => true)
            expect(handler.event.origin_headers).to eq(header: "value")
          end

          it "is instrumented" do
            expect(configuration.instrumenter).to receive(:instrument).with("Hermes.Consumer.process")

            process
          end

          it "creates trace" do
            expect {
              process
            }.to change { Hermes::DistributedTrace.count }.by(1)
          end
        end

        context "with RPC" do
          before do
            event_handler.handle(EventClassForTestingConsumerBuilder, with: handler, async: false, rpc: true)
          end

          it "builds a Hutch consumer class that directly calls the event handler and replies back
          handling RPC call" do
            expect {
              process
            }.to change { fake_exchange.messages.count }.by(1)

            expect(handler.event).to be_instance_of(EventClassForTestingConsumerBuilder)
            expect(handler.event.bookingsync).to eq(true)
            expect(handler.event.origin_body).to eq("bookingsync" => true)
            expect(handler.event.origin_headers).to eq(header: "value")
            expect(fake_exchange.messages.first.response).to eq("{\"processed\":true}")
            expect(fake_exchange.messages.first.routing_key).to eq("bookingsync_queue")
            expect(fake_exchange.messages.first.correlation_id).to eq("bookingsync_123")
            expect(fake_exchange.messages.first.headers).to eq Hermes::DistributedTrace.last.event_headers
            expect(fake_exchange.messages.first.headers.keys).to eq(
              ["X-B3-TraceId", "X-B3-ParentSpanId", "X-B3-SpanId", "X-B3-Sampled", "service"]
            )
          end

          it "creates trace" do
            expect {
              process
            }.to change { Hermes::DistributedTrace.count }.by(1)
          end

          it "is instrumented" do
            expect(configuration.instrumenter).to receive(:instrument).with("Hermes.Consumer.process")

            process
          end

          context "when error is raised during processing" do
            context "when the error is related to Postgres server closing the connection" do
              context "when the database connection provider is configured and distributed traces are supposed to be stored" do
                let(:error_message) { "PG::ConnectionBad: PQsocket() can't get socket descriptor" }

                before do
                  allow(configuration.database_connection_provider.connection_pool).to receive(:disconnect!).and_call_original
                  allow(Hermes::DistributedTrace.connection_pool).to receive(:disconnect!).and_call_original

                  allow(Hermes::DependenciesContainer["event_processor"]).to receive(:call)
                    .and_raise(ActiveRecord::StatementInvalid.new(error_message))
                end

                it { is_expected_block.to raise_error(ActiveRecord::StatementInvalid, error_message) }

                it "releases DB connections" do
                  process rescue ActiveRecord::StatementInvalid

                  expect(configuration.database_connection_provider.connection_pool).to have_received(:disconnect!).at_least(1)
                  expect(Hermes::DistributedTrace.connection_pool).to have_received(:disconnect!).at_least(1)
                end
              end

              context "when the database connection provider is not configured and distributed traces are not supposed to be stored" do
                let(:error_message) { "PG::ConnectionBad: PQsocket() can't get socket descriptor" }

                before do
                  allow(Hermes.configuration).to receive(:database_connection_provider).and_return(nil)
                  allow(Hermes.configuration).to receive(:store_distributed_traces?).and_return(false)

                  allow(Hermes::DependenciesContainer["event_processor"]).to receive(:call)
                    .and_raise(ActiveRecord::StatementInvalid.new(error_message))
                end

                it "does not attempt to release any connections and blows up with the original error" do
                  expect {
                    process
                  }.to raise_error ActiveRecord::StatementInvalid, error_message
                end
              end
            end

            context "when the error is not related to Postgres server closing the connection" do
              before do
                allow(configuration.database_connection_provider.connection_pool).to receive(:disconnect!).and_call_original
                allow(Hermes::DistributedTrace.connection_pool).to receive(:disconnect!).and_call_original

                allow(Hermes::DependenciesContainer["event_processor"]).to receive(:call).and_raise(StandardError.new("some error"))
              end

              it { is_expected_block.to raise_error(StandardError, "some error") }

              it "does not release any connections" do
                process rescue StandardError

                expect(configuration.database_connection_provider.connection_pool).not_to have_received(:disconnect!)
                expect(Hermes::DistributedTrace.connection_pool).not_to have_received(:disconnect!)
              end
            end
          end
        end
      end
    end

    it "registers a class under a constant derived from event name and HutchConsumer suffix" do
      consumer = build

      expect(consumer).to eq EventClassForTestingConsumerBuilderHutchConsumer
    end

    describe "consumer config" do
      context "without extra config" do
        class AnotherEventClassForTestingConsumerBuilderWithoutExtraConfig < Hermes::BaseEvent
          def self.routing_key
            # add extra suffix in case Rabbit complains about "precondition failed" when a queue was registered with different config
            "routing_key.another_for_consumer_without_extra_config_test_#{Time.now.to_i}"
          end

          def self.to_s
            "AnotherEventClassForTestingConsumerBuilderWithoutExtraConfig"
          end

          attribute :bookingsync, Types::Nominal::String
        end

        subject(:consumer) { builder.build(AnotherEventClassForTestingConsumerBuilderWithoutExtraConfig) }

        let(:expected_arguments) do
          {}
        end

        it "does not set any arguments on consumer by default" do
          expect(consumer.get_arguments).to eq(expected_arguments)
        end
      end

      context "with extra config" do
        class AnotherEventClassForTestingConsumerBuilderWithExtraConfig < Hermes::BaseEvent
          def self.routing_key
            # add extra suffix in case Rabbit complains about "precondition failed" when a queue was registered with different config
            "routing_key.another_for_consumer_with_extra_config_test_#{Time.now.to_i}"
          end

          def self.to_s
            "AnotherEventClassForTestingConsumerBuilderWithExtraConfig"
          end

          attribute :bookingsync, Types::Nominal::String
        end

        subject(:consumer) { builder.build(AnotherEventClassForTestingConsumerBuilderWithExtraConfig, consumer_config: consumer_config) }

        let(:consumer_config) do
          -> do
            classic_queue
            quorum_queue initial_group_size: 3
            arguments "x-max-length" => 10
          end
        end
        let(:expected_arguments) do
          {
            "x-max-length" => 10,
            "x-quorum-initial-group-size" => 3,
            "x-queue-type" => "quorum"
          }
        end

        it "allows to provider extra config for consumer" do
          expect(consumer.get_arguments).to eq(expected_arguments)
        end
      end
    end
  end
end
