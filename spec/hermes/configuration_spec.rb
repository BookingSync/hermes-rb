require "spec_helper"

RSpec.describe Hermes::Configuration do
  describe "adapter" do
    subject(:adapter) { configuration.adapter }

    let(:configuration) { described_class.new }

    before do
      configuration.adapter = "bookingsync"
    end

    it { is_expected.to eq "bookingsync" }
  end

  describe "clock" do
    subject(:clock) { configuration.clock }

    let(:configuration) { described_class.new }

    before do
      configuration.clock = Time
    end

    it { is_expected.to eq Time }
  end

  describe "clock" do
    subject(:clock) { configuration.clock }

    let(:configuration) { described_class.new }

    before do
      configuration.clock = Time
    end

    it { is_expected.to eq Time }
  end

  describe "application_prefix" do
    subject(:application_prefix) { configuration.application_prefix }

    let(:configuration) { described_class.new }

    before do
      configuration.application_prefix = "bookingsync"
    end

    it { is_expected.to eq "bookingsync" }
  end

  describe "background_processor" do
    subject(:background_processor) { configuration.background_processor }

    let(:configuration) { described_class.new }

    before do
      configuration.background_processor = Object
    end

    it { is_expected.to eq Object }
  end

  describe "enqueue_method" do
    subject(:enqueue_method) { configuration.enqueue_method }

    let(:configuration) { described_class.new }

    before do
      configuration.enqueue_method = :whatever_it_takes
    end

    it { is_expected.to eq :whatever_it_takes }
  end

  describe "event_handler" do
    subject(:event_handler) { configuration.event_handler }

    let(:configuration) { described_class.new }

    before do
      configuration.event_handler = :bookingsync
    end

    it { is_expected.to eq :bookingsync }
  end

  describe "hutch" do
    describe "#configure_hutch" do
      subject(:configure_hutch) do
        configuration.configure_hutch do |hutch|
          hutch.uri = "URI"
          hutch.force_publisher_confirms = false
        end
      end

      let(:configuration) { described_class.new }
      let(:hutch_config) { configuration.hutch }

      before do
        Hutch::Config.set(:tracer, nil)
        Hutch::Config.set(:uri, nil)
        Hutch::Config.set(:force_publisher_confirms, true)
      end

      it "assigns values to hutch config" do
        expect {
          configure_hutch
        }.to change { hutch_config.uri }.from(nil).to("URI")
        .and change { hutch_config.force_publisher_confirms }.from(true).to(false)
      end

      it "assigns configuration to Hutch::Config from Hutch gem" do
        expect {
          configure_hutch
        }.to change { Hutch::Config.get(:uri) }.from(nil).to("URI")
        .and change { Hutch::Config.get(:force_publisher_confirms) }.from(true).to(false)
        .and change { Hutch::Config.get(:tracer) }.to(Hermes::Tracers::Datadog)
      end
    end

    describe "uri" do
      subject(:hutch_uri) { configuration.hutch.uri }

      let(:configuration) { described_class.new }

      before do
        configuration.configure_hutch do |hutch|
          hutch.uri = "#WhateverItTakes"
        end
      end

      it { is_expected.to eq "#WhateverItTakes" }
    end

    describe "force_publisher_confirms" do
      subject(:force_publisher_confirms) { configuration.hutch.force_publisher_confirms }

      let(:configuration) { described_class.new }

      context "when set to false" do
        before do
          configuration.configure_hutch do |hutch|
            hutch.force_publisher_confirms = false
          end
        end

        it { is_expected.to eq false }
      end

      context "when set to true" do
        before do
          configuration.configure_hutch do |hutch|
            hutch.force_publisher_confirms = true
          end
        end

        it { is_expected.to eq true }
      end

      context "when not set explicitly" do
        it { is_expected.to eq true }
      end
    end

    describe "enable_http_api_use" do
      subject(:enable_http_api_use) { configuration.hutch.enable_http_api_use }

      let(:configuration) { described_class.new }

      context "when set to false" do
        before do
          configuration.configure_hutch do |hutch|
            hutch.enable_http_api_use = false
          end
        end

        it { is_expected.to eq false }
      end

      context "when set to true" do
        before do
          configuration.configure_hutch do |hutch|
            hutch.enable_http_api_use = true
          end
        end

        it { is_expected.to eq true }
      end

      context "when not set explicitly" do
        it { is_expected.to eq false }
      end
    end

    describe "tracer" do
      subject(:tracer) { configuration.hutch.tracer }

      let(:configuration) { described_class.new }

      context "when a custom tracer is set" do
        before do
          configuration.configure_hutch do |hutch|
            hutch.tracer = custom_tracer
          end
        end

        let(:custom_tracer) { double(:custom_tracer) }

        it { is_expected.to eq custom_tracer }
      end

      context "when a custom tracer is not set" do
        before do
          allow(Object).to receive(:const_defined?).and_call_original
        end

        context "when Datadog constant is defined and NewRelic constant is defined" do
          it { is_expected.to eq Hermes::Tracers::Datadog }
        end

        context "when Datadog constant is defined and NewRelic constant is not defined" do
          before do
            allow(Object).to receive(:const_defined?).with("NewRelic").and_return(false)
            allow(Object).to receive(:const_defined?).with("Datadog").and_return(true)
          end

          it { is_expected.to eq Hermes::Tracers::Datadog }
        end

        context "when Datadog constant is not defined and NewRelic constant is defined" do
          before do
            allow(Object).to receive(:const_defined?).with("Datadog").and_return(false)
            allow(Object).to receive(:const_defined?).with("NewRelic").and_return(true)
          end

          it { is_expected.to eq Hutch::Tracers::NewRelic }
        end

        context "when neither Datadog constant is defined, nor NewRelic constant is defined" do
          before do
            allow(Object).to receive(:const_defined?).with("NewRelic").and_return(false)
            allow(Object).to receive(:const_defined?).with("Datadog").and_return(false)
          end

          it { is_expected.to eq Hutch::Tracers::NullTracer }
        end
      end
    end

    describe "#commit_config" do
      subject(:commit_config) do
        hutch_config.force_publisher_confirms = true
        hutch_config.uri = "URI"
        hutch_config.commit_config
      end

      let(:configuration) { described_class.new }
      let(:hutch_config) { configuration.hutch }

      before do
        Hutch::Config.set(:tracer, nil)
        Hutch::Config.set(:uri, nil)
        Hutch::Config.set(:force_publisher_confirms, false)
      end

      after do
        Hutch::Config.set(:tracer, nil)
      end

      it "assigns configuration to Hutch::Config from Hutch gem" do
        expect {
          commit_config
        }.to change { Hutch::Config.get(:uri) }.from(nil).to("URI")
        .and change { Hutch::Config.get(:force_publisher_confirms) }.from(false).to(true)
      end

      context "tracers" do
        context "when custom tracer was not set" do
          before do
            allow(Object).to receive(:const_defined?).and_call_original
          end

          context "when NewRelic constant is defined and Datadog constant is not" do
            before do
              allow(Object).to receive(:const_defined?).with("Datadog").and_return(false)
            end

            it "sets NewRelic tracer" do
              expect {
                commit_config
              }.to change { Hutch::Config.get(:tracer) }.to(Hutch::Tracers::NewRelic)
            end
          end

          context "when Datadog constant is defined and NewRelic constant is not" do
            before do
              allow(Object).to receive(:const_defined?).with("NewRelic").and_return(false)
            end

            it "sets Datadog tracer" do
              expect {
                commit_config
              }.to change { Hutch::Config.get(:tracer) }.to(Hermes::Tracers::Datadog)
            end
          end

          context "when Datadog constant is defined and NewRelic constant is also defined" do
            it "sets Datadog tracer" do
              expect {
                commit_config
              }.to change { Hutch::Config.get(:tracer) }.to(Hermes::Tracers::Datadog)
            end
          end

          context "when neither NewRelic, nor Datadog constants are defined" do
            before do
              allow(Object).to receive(:const_defined?).with("NewRelic").and_return(false)
              allow(Object).to receive(:const_defined?).with("Datadog").and_return(false)
            end

            it "sets Hutch::Tracers::NullTracer" do
              expect {
                commit_config
              }.to change { Hutch::Config.get(:tracer) }.to(Hutch::Tracers::NullTracer)
            end
          end
        end

        context "when custom tracer was set" do
          before do
            hutch_config.tracer = tracer
          end

          let(:tracer) { double(:tracer) }

          it "sets tracer" do
            expect {
              commit_config
            }.to change { Hutch::Config.get(:tracer) }.to(tracer)
          end
        end
      end
    end
  end

  describe "rpc_call_timeout" do
    subject(:rpc_call_timeout) { configuration.rpc_call_timeout }

    let(:configuration) { described_class.new }

    context "when it's set" do
      before do
        configuration.rpc_call_timeout = :bookingsync
      end

      it { is_expected.to eq :bookingsync }
    end

    context "when it's not set" do
      it { is_expected.to eq 10 }
    end
  end

  describe "instrumenter" do
    subject(:instrumenter) { configuration.instrumenter }

    let(:configuration) { described_class.new }

    context "when it's set" do
      before do
        configuration.instrumenter = :instrumenter
      end

      it { is_expected.to eq :instrumenter }
    end

    context "when it's not set" do
      it { is_expected.to eq Hermes::NullInstrumenter }
    end
  end

  describe "#logger" do
    subject(:logger) { configuration.logger }

    let(:configuration) { described_class.new }

    context "when it's set" do
      before do
        configuration.logger = :logger
      end

      it { is_expected.to eq :logger }
    end

    context "when it's not set" do
      it { is_expected.to be_a Hermes::Logger }
    end
  end

  describe "distributed_tracing_database_uri" do
    subject(:distributed_tracing_database_uri) { configuration.distributed_tracing_database_uri }

    let(:configuration) { described_class.new }

    context "when it's set" do
      before do
        configuration.distributed_tracing_database_uri = :distributed_tracing_database_uri
      end

      it { is_expected.to eq :distributed_tracing_database_uri }
    end

    context "when it's not set" do
      it { is_expected.to eq nil }
    end
  end

  describe "store_distributed_traces?" do
    subject(:store_distributed_traces?) { configuration.store_distributed_traces? }

    let(:configuration) { described_class.new }

    context "when distributed_tracing_database_uri is set" do
      before do
        configuration.distributed_tracing_database_uri = :distributed_tracing_database_uri
      end

      it { is_expected.to eq true }
    end

    context "when distributed_tracing_database_uri is not set" do
      it { is_expected.to eq false }
    end
  end

  describe "distributed_tracing_database_table" do
    subject(:distributed_tracing_database_table) { configuration.distributed_tracing_database_table }

    let(:configuration) { described_class.new }

    context "when distributed_tracing_database_table is set" do
      before do
        configuration.distributed_tracing_database_table = "example_table_name"
      end

      it { is_expected.to eq "example_table_name" }
    end

    context "when distributed_tracing_database_uri is not set" do
      it { is_expected.to eq "hermes_distributed_traces" }
    end
  end

  describe "distributes_tracing_mapper" do
    subject(:distributes_tracing_mapper) { configuration.distributes_tracing_mapper }

    let(:configuration) { described_class.new }
    let(:attributes) do
      {
        event_class: "name",
        event_body: "body"
      }
    end

    context "when distributes_tracing_mapper is set" do
      context "when the object responds to :call method" do
        before do
          configuration.distributes_tracing_mapper = ->(attrs) { attrs.slice(:event_class) }
        end

        it "returns that mapper" do
          expect(distributes_tracing_mapper.call(attributes)).to eq(event_class: "name")
        end
      end

      context "when the object does not respond to :call method" do
        it "raises error" do
          expect {
            configuration.distributes_tracing_mapper = :invalid
          }.to raise_error ArgumentError
        end
      end
    end

    context "when distributed_tracing_database_uri is not set" do
      it { is_expected.to be_instance_of(Hermes::DistributedTrace::Mapper) }
    end
  end

  describe "database_error_handler" do
    subject(:database_error_handler) { configuration.database_error_handler }

    let(:configuration) { described_class.new }

    context "when error_notification_service is set" do
      before do
        configuration.database_error_handler = "database_error_handler"
      end

      it { is_expected.to eq "database_error_handler" }
    end

    context "when error_notification_service is not set" do
      it { is_expected.to be_instance_of Hermes::DatabaseErrorHandler }
    end
  end

  describe "error_notification_service" do
    subject(:error_notification_service) { configuration.error_notification_service }

    let(:configuration) { described_class.new }

    context "when error_notification_service is set" do
      before do
        configuration.error_notification_service = "error_notification_service"
      end

      it { is_expected.to eq "error_notification_service" }
    end

    context "when error_notification_service is not set" do
      it { is_expected.to eq Hermes::NullErrorNotificationService }
    end
  end

  describe "producer_error_handler" do
    subject(:producer_error_handler) { configuration.producer_error_handler }

    let(:configuration) { described_class.new }

    context "when producer_error_handler is set" do
      before do
        configuration.producer_error_handler = "producer_error_handler"
      end

      it { is_expected.to eq "producer_error_handler" }
    end

    context "when producer_error_handler is not set" do
      it { is_expected.to eq Hermes::ProducerErrorHandler::NullHandler }
    end
  end

  describe "producer_error_handler_job_class" do
    subject(:producer_error_handler_job_class) { configuration.producer_error_handler_job_class }

    let(:configuration) { described_class.new }

    context "when producer_error_handler_job_class is set" do
      before do
        configuration.producer_error_handler_job_class = "producer_error_handler_job_class"
      end

      it { is_expected.to eq "producer_error_handler_job_class" }
    end

    context "when producer_error_handler_job_class is not set" do
      it { is_expected.to eq nil }
    end
  end

  describe "producer_retryable" do
    subject(:producer_retryable) { configuration.producer_retryable }

    let(:configuration) { described_class.new }

    context "when producer_retryable is set" do
      before do
        configuration.producer_retryable = "producer_retryable"
      end

      it { is_expected.to eq "producer_retryable" }
    end

    context "when producer_retryable is not set" do
      it { is_expected.to be_instance_of Hermes::Retryable }
    end
  end

  describe "#enable_safe_producer" do
    subject(:enable_safe_producer) { configuration.enable_safe_producer(producer_error_handler_job_class) }

    let(:configuration) { described_class.new }
    let(:producer_error_handler_job_class) { double(:producer_error_handler_job_class) }

    it "sets producer_error_handler_job_class" do
      expect {
        enable_safe_producer
      }.to change { configuration.producer_error_handler_job_class }.to(producer_error_handler_job_class)
    end

    it "sets producer_error_handler to Hermes::ProducerErrorHandler::SafeHandler" do
      expect {
        enable_safe_producer
      }.to change { configuration.producer_error_handler }.to(instance_of(Hermes::ProducerErrorHandler::SafeHandler))
    end
  end

  describe "logger_params_filter" do
    subject(:logger_params_filter) { configuration.logger_params_filter }

    let(:configuration) { described_class.new }

    context "when logger_params_filter is set" do
      before do
        configuration.logger_params_filter = "logger_params_filter"
      end

      it { is_expected.to eq "logger_params_filter" }
    end

    context "when logger_params_filter is not set" do
      it { is_expected.to be_instance_of Hermes::Logger::ParamsFilter }
    end
  end

  describe "database_connection_provider" do
    subject(:database_connection_provider) { configuration.database_connection_provider }

    let(:configuration) { described_class.new }

    context "when database_connection_provider is set" do
      before do
        configuration.database_connection_provider = "database_connection_provider"
      end

      it { is_expected.to eq "database_connection_provider" }
    end

    context "when database_connection_provider is not set" do
      it { is_expected.to eq nil }
    end
  end
end
