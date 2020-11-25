require "spec_helper"

RSpec.describe Hermes::EventProducer do
  describe ".publish", :freeze_time do
    let(:producer) { Hermes::EventProducer }
    let(:publisher) { Hermes::Publisher.instance.current_adapter }
    let(:serializer) do
      Class.new do
        def serialize(payload, version)
          payload.merge(version: version)
        end
      end.new
    end
    let(:event) do
      Class.new do
        def routing_key
          "#WhateverItTakes"
        end

        def as_json
          {
            bookingsync: true
          }
        end

        def version
          1
        end
      end.new
    end
    let(:expected_event_payload) do
      {
        bookingsync: true,
        meta: {
          correlation_uuid: correlation_uuid_generator.uuid,
          timestamp: clock.now.iso8601,
          event_version: 1
        }
      }
    end
    let(:expected_routing_key) { "#WhateverItTakes" }
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
    let(:properties) do
      {
        propeties: true
      }
    end
    let(:options) do
      {
        options: true
      }
    end

    before do
      Hermes.configuration.clock = clock
      Hermes.configuration.correlation_uuid_generator = correlation_uuid_generator
      Hermes.configuration.adapter = :in_memory
    end

    around do |example|
      VCR.use_cassette("Hermes::EventProducer") do
        example.run
      end
    end

    context "when properties/options are passed" do
      subject(:publish) { producer.publish(event, properties, options) }

      it "produces and publishes event using the right routing key and passed properties and options" do
        publish

        expect(publisher.store).to eq [
          {
            routing_key: expected_routing_key,
            payload: expected_event_payload,
            options: options,
            properties: properties
          }
        ]
      end
    end

    context "when properties/options are not passed" do
      subject(:publish) { producer.publish(event) }

      it "produces and publishes event using the right routing key using default dependencies" do
        publish

        expect(publisher.store).to eq [
          { routing_key: expected_routing_key, payload: expected_event_payload }
        ]
      end
    end
  end

  describe ".build" do
    subject(:build) { Hermes::EventProducer.build }

    it { is_expected.to be_a(Hermes::EventProducer) }
  end

  describe "#publish" do
    let(:producer) { Hermes::EventProducer.new(publisher: publisher, serializer: serializer) }
    let(:publisher) { Hermes::Publisher::InMemoryAdapter.new }
    let(:serializer) do
      Class.new do
        def serialize(payload, version)
          payload.merge(version: version)
        end
      end.new
    end
    let(:event) do
      Class.new do
        def routing_key
          "#WhateverItTakes"
        end

        def as_json
          {
            bookingsync: true
          }
        end

        def version
          1
        end
      end.new
    end
    let(:properties) do
      {
        propeties: true
      }
    end
    let(:options) do
      {
        options: true
      }
    end
    let(:expected_event_payload) do
      {
        bookingsync: true,
        version: 1
      }
    end
    let(:expected_routing_key) { "#WhateverItTakes" }

    context "when properties/options are passed" do
      subject(:publish) { producer.publish(event, properties, options) }

      it "produces and publishes event using the right routing key using default dependencies" do
        publish

        expect(publisher.store).to eq [
          {
            routing_key: expected_routing_key,
            payload: expected_event_payload,
            properties: properties,
            options: options
          }
        ]
      end
    end

    context "when properties/options are not passed" do
      subject(:publish) { producer.publish(event) }

      it "produces and publishes event using the right routing key using default dependencies" do
        publish

        expect(publisher.store).to eq [
          { routing_key: expected_routing_key, payload: expected_event_payload }
        ]
      end
    end

    describe "instrumentation" do
      subject(:publish) { producer.publish(event) }

      it "is instrumented" do
        expect(Hermes.configuration.instrumenter).to receive(:instrument)
          .with("Hermes.EventProducer.publish")
          .and_call_original

        publish
      end
    end
  end
end
