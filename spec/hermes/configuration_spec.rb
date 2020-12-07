require "spec_helper"

RSpec.describe Hermes::Configuration do
  describe "adapter" do
    subject(:adapter) { configuration.adapter }

    let(:configuration) { Hermes::Configuration.new }

    before do
      configuration.adapter = "bookingsync"
    end

    it { is_expected.to eq "bookingsync" }
  end

  describe "clock" do
    subject(:clock) { configuration.clock }

    let(:configuration) { Hermes::Configuration.new }

    before do
      configuration.clock = Time
    end

    it { is_expected.to eq Time }
  end

  describe "clock" do
    subject(:clock) { configuration.clock }

    let(:configuration) { Hermes::Configuration.new }

    before do
      configuration.clock = Time
    end

    it { is_expected.to eq Time }
  end

  describe "application_prefix" do
    subject(:application_prefix) { configuration.application_prefix }

    let(:configuration) { Hermes::Configuration.new }

    before do
      configuration.application_prefix = "bookingsync"
    end

    it { is_expected.to eq "bookingsync" }
  end

  describe "background_processor" do
    subject(:background_processor) { configuration.background_processor }

    let(:configuration) { Hermes::Configuration.new }

    before do
      configuration.background_processor = Object
    end

    it { is_expected.to eq Object }
  end

  describe "enqueue_method" do
    subject(:enqueue_method) { configuration.enqueue_method }

    let(:configuration) { Hermes::Configuration.new }

    before do
      configuration.enqueue_method = :whatever_it_takes
    end

    it { is_expected.to eq :whatever_it_takes }
  end

  describe "event_handler" do
    subject(:event_handler) { configuration.event_handler }

    let(:configuration) { Hermes::Configuration.new }

    before do
      configuration.event_handler = :bookingsync
    end

    it { is_expected.to eq :bookingsync }
  end

  describe "hutch" do
    subject(:hutch_uri) { configuration.hutch.uri }

    let(:configuration) { Hermes::Configuration.new }

    before do
      configuration.configure_hutch do |hutch|
        hutch.uri = "#WhateverItTakes"
      end
    end

    it { is_expected.to eq "#WhateverItTakes" }
  end

  describe "rpc_call_timeout" do
    subject(:rpc_call_timeout) { configuration.rpc_call_timeout }

    let(:configuration) { Hermes::Configuration.new }

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

    let(:configuration) { Hermes::Configuration.new }

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

    let(:configuration) { Hermes::Configuration.new }

    it { is_expected.to be_a Hermes::Logger }
  end

  describe "distributed_tracing_database_uri" do
    subject(:distributed_tracing_database_uri) { configuration.distributed_tracing_database_uri }

    let(:configuration) { Hermes::Configuration.new }

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

    let(:configuration) { Hermes::Configuration.new }

    context "when distributed_tracing_database_uri set" do
      before do
        configuration.distributed_tracing_database_uri = :distributed_tracing_database_uri
      end

      it { is_expected.to eq true }
    end

    context "when distributed_tracing_database_uri is not set" do
      it { is_expected.to eq false }
    end
  end

  describe "distributed_tracing_database_table?" do
    subject(:distributed_tracing_database_table) { configuration.distributed_tracing_database_table }

    let(:configuration) { Hermes::Configuration.new }

    context "when distributed_tracing_database_table set" do
      before do
        configuration.distributed_tracing_database_table = "example_table_name"
      end

      it { is_expected.to eq "example_table_name" }
    end

    context "when distributed_tracing_database_uri is not set" do
      it { is_expected.to eq "hermes_distributed_traces" }
    end
  end
end
