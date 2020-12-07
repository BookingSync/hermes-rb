require "spec_helper"

RSpec.describe "Event Producer Integration With Hutch Publisher", :with_application_prefix do
  class EventForTestingIntegrationWithHutchPublisher < Hermes::BaseEvent
    attribute :message, Types::Strict::String
  end

  class HandlerForTestingIntegrationBetweenHutchAndEventProducer
    def self.call(event)
      File.write("/tmp/rabbit.log", event.message)
    end
  end

  describe "Hutch" do
    subject(:publish) { Hermes::EventProducer.build.publish(event) }

    let(:do_whatever_it_takes_to_avoid_flaky_mess) { sleep 0.5 }
    let(:event) { EventForTestingIntegrationWithHutchPublisher.new(message: message) }
    let(:message) { "bookingsync + rabbit = :hearts:" }
    let(:file_path) { "/tmp/rabbit.log" }
    let(:clock) do
      Class.new do
        def now
          Time.new(2018, 1, 1, 12, 0, 0, 0)
        end
      end.new
    end
    let(:event_handler) do
      Hermes::EventHandler.new.tap do |handler|
        handler.handle_events do
          handle EventForTestingIntegrationWithHutchPublisher, with: HandlerForTestingIntegrationBetweenHutchAndEventProducer,
                 async: false
        end
      end
    end
    let(:trace_1) { Hermes::DistributedTrace.order(:id).first }
    let(:trace_2) { Hermes::DistributedTrace.order(:id).second }
    let(:configuration) { Hermes.configuration }

    before do
      @worker_thread = Thread.new do
        Hutch.connect
        worker = Hutch::Worker.new(Hutch.broker, Hutch.consumers, Hutch::Config.setup_procs)
        worker.run
      end

      sleep 0.2
    end

    around do |example|
      hutch_publisher = Hermes::Publisher::HutchAdapter.new
      Hermes::Publisher.instance.current_adapter = hutch_publisher

      original_distributed_tracing_database_uri = configuration.distributed_tracing_database_uri
      original_event_handler = configuration.event_handler
      original_clock = configuration.clock

      Hermes.configure do |config|
        config.distributed_tracing_database_uri = ENV["DISTRIBUTED_TRACING_DATABASE_URI"]
        config.event_handler = event_handler
        config.clock = clock
      end

      VCR.use_cassette("hutch.integration_spec_with_event_producer") do
        example.run
      end

      Hermes.configure do |config|
        config.distributed_tracing_database_uri = original_distributed_tracing_database_uri
        config.event_handler = original_event_handler
        config.clock = original_clock
      end
    end

    after do
      File.delete(file_path) if File.exist?(file_path)
      @worker_thread.kill
    end

    it "publishes messages that can be consumed by the other consumer" do
      publish

      do_whatever_it_takes_to_avoid_flaky_mess

      expect(File.read(file_path)).to eq "bookingsync + rabbit = :hearts:"
    end

    it "creates traces: client - server" do
      expect {
        publish
      }.to change { Hermes::DistributedTrace.count }.by(2)

      expect([trace_1.trace, trace_2.trace].uniq).to eq [trace_1.trace]
      expect([trace_1.span, trace_2.span].uniq).to eq [trace_1.span]
      expect([trace_1.parent_span, trace_2.parent_span]).to match_array [trace_1.span, nil]
      expect(trace_1.event_class).to eq "EventForTestingIntegrationWithHutchPublisher"
      expect(trace_2.event_class).to eq "EventForTestingIntegrationWithHutchPublisher"
    end
  end
end
