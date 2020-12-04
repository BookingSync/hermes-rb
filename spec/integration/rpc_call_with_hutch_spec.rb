require "spec_helper"

RSpec.describe "RPC call with Hutch", :with_application_prefix do
  describe "when RPC call is performed" do
    subject(:call) { rpc_client.call(event) }

    let(:rpc_client) { Hermes::RpcClient }

    class DummyEventToTestRpcIntegration < Hermes::BaseEvent
      def self.routing_key
        "hutch.integration_spec_for_rpc"
      end

      def initialize(*)
      end

      def routing_key
        self.class.routing_key
      end

      def as_json
        {
          message: "bookingsync + rabbit = :hearts:"
        }
      end

      def version
        1
      end
    end

    class DummyEventToTestRpcIntegrationHandler
      def self.call(event)
        event.as_json
      end
    end

    let(:event) { DummyEventToTestRpcIntegration.new }
    let(:correlation_uuid_generator) do
      Class.new do
        def uuid
          "#WhateverItTakes"
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
    let(:instrumenter) { Hermes.configuration.instrumenter }

    before do
      allow(instrumenter).to receive(:instrument).and_call_original

      hutch_publisher = Hermes::Publisher::HutchAdapter.new

      config = Hermes.configuration
      Hermes::Publisher.instance.current_adapter = hutch_publisher
      config.clock = clock
      config.correlation_uuid_generator = correlation_uuid_generator
      config.application_prefix = "bookingsync_hermes"

      event_handler = Hermes::EventHandler.new
      config.event_handler = event_handler

      event_handler.handle_events do
        handle DummyEventToTestRpcIntegration, with: DummyEventToTestRpcIntegrationHandler, async: false, rpc: true
      end

      @worker_thread = Thread.new do
        Hutch.connect

        worker = Hutch::Worker.new(Hutch.broker, Hutch.consumers, Hutch::Config.setup_procs)
        worker.run
      end

      sleep 0.2
    end

    after do
      @worker_thread.kill
    end

    context "when client receives a response from the server" do
      it "returns a parsed response from server" do
        response = call

        expect(response).to eq("message" => "bookingsync + rabbit = :hearts:")
      end

      it "closes connection, channel and consumer" do
        expect_any_instance_of(Hutch::Adapters::BunnyAdapter).to receive(:close).and_call_original
        expect_any_instance_of(Bunny::Channel).to receive(:close).and_call_original
        expect_any_instance_of(Bunny::Consumer).to receive(:cancel).and_call_original

        call
      end

      it "is instrumented" do
        call

        expect(instrumenter).to have_received(:instrument).with("Hermes.RpcClient.broker_connect")
        expect(instrumenter).to have_received(:instrument).with("Hermes.RpcClient.call")
        expect(instrumenter).to have_received(:instrument).with("Hermes.RpcClient.close_connection")
      end
    end

    context "when client does not receive a response from the server in a timely manner" do
      let(:rpc_client) { Hermes::RpcClient.new(rpc_call_timeout: 2) }

      before do
        allow(DummyEventToTestRpcIntegrationHandler).to receive(:call) { sleep 3.0 }
      end

      it { is_expected_block.to raise_error Hermes::RpcClient::RpcTimeoutError  }

      it "closes connection, channel and consumer" do
        expect_any_instance_of(Hutch::Adapters::BunnyAdapter).to receive(:close).and_call_original
        expect_any_instance_of(Bunny::Channel).to receive(:close).and_call_original
        expect_any_instance_of(Bunny::Consumer).to receive(:cancel).and_call_original

        begin
          call
        rescue Hermes::RpcClient::RpcTimeoutError
        end
      end
    end

    context "when an error is raised" do
      before do
        allow_any_instance_of(Bunny::Exchange).to receive(:publish) { raise "forced failure" }
      end

      it "re-raises that error" do
        expect {
          call
        }.to raise_error /forced failure/
      end

      it "closes connection and channel" do
        expect_any_instance_of(Hutch::Adapters::BunnyAdapter).to receive(:close).and_call_original
        expect_any_instance_of(Bunny::Channel).to receive(:close).and_call_original

        begin
          call
        rescue StandardError
        end
      end
    end
  end
end
