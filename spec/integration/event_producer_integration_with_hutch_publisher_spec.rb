require "spec_helper"

RSpec.describe "Event Producer Integration With Hutch Publisher", :with_application_prefix do
  class FakeConsumerForTestingIntegrationBetweenHutchAndEventProducer
    include Hutch::Consumer
    consume "hutch.integration_spec_with_event_producer"

    def process(message)
      File.write("/tmp/rabbit.log", message.body[:message])
    end
  end

  describe "Hutch" do
    subject(:publish) { Hermes::EventProducer.build.publish(event) }

    let(:do_whatever_it_takes_to_avoid_flaky_mess) { sleep 0.5 }
    let(:event) do
      Class.new(Hermes::BaseEvent) do
        def as_json
          {
            message: "bookingsync + rabbit = :hearts:"
          }
        end

        def routing_key
          "hutch.integration_spec_with_event_producer"
        end

        def version
          1
        end
      end.new
    end
    let(:file_path) { "/tmp/rabbit.log" }
    let(:clock) do
      Class.new do
        def now
          Time.new(2018, 1, 1, 12, 0, 0, 0)
        end
      end.new
    end

    before do
      hutch_publisher = Hermes::Publisher::HutchAdapter.new
      Hermes::Publisher.instance.current_adapter = hutch_publisher
      Hermes.configuration.clock = clock

      @worker_thread = Thread.new do
        Hutch.connect
        worker = Hutch::Worker.new(Hutch.broker, Hutch.consumers, Hutch::Config.setup_procs)
        worker.run
      end

      sleep 0.2
    end

    around do |example|
      original_distributed_tracing_database_uri = Hermes.configuration.distributed_tracing_database_uri

      Hermes.configure do |config|
        config.distributed_tracing_database_uri = ENV["DISTRIBUTED_TRACING_DATABASE_URI"]
      end

      VCR.use_cassette("hutch.integration_spec_with_event_producer") do
        example.run
      end

      Hermes.configure do |config|
        config.distributed_tracing_database_uri = original_distributed_tracing_database_uri
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

    it "creates traces" do
      expect {
        publish
      }.to change { Hermes::DistributedTrace.count }.by(1)
    end
  end
end
