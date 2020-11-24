require "spec_helper"

RSpec.describe Hermes::Publisher::InMemoryAdapter do
  describe ".connect" do
    subject(:connect) { described_class.connect }

    it "does nothing, it's just there for duck-typing" do
      expect {
        connect
      }.not_to raise_error
    end
  end

  describe "store/publish" do
    subject(:store) { publisher.store }

    let(:publisher) { Hermes::Publisher::InMemoryAdapter.new }
    let(:routing_key) { "bookingsync" }
    let(:payload) do
      {
        "#WhateverItTakes" => true
      }
    end

    context "when properties/options are not passed" do
      let(:expected_store_content) do
        [
          { routing_key: routing_key, payload: payload }
        ]
      end

      it "keeps all the published events in the store" do
        expect {
          publisher.publish(routing_key, payload)
        }.to change { store }.from([]).to(expected_store_content)
      end
    end

    context "when properties/options are passed" do
      let(:properties) do
        {
          properties: true
        }
      end
      let(:options) do
        {
          options: true
        }
      end
      let(:expected_store_content) do
        [
          { routing_key: routing_key, payload: payload, properties: properties, options: options }
        ]
      end

      it "keeps all the published events in the store with properties and options that were passed" do
        expect {
          publisher.publish(routing_key, payload, properties, options)
        }.to change { store }.from([]).to(expected_store_content)
      end
    end
  end
end
