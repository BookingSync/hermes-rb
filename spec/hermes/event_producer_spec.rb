require "spec_helper"

RSpec.describe Hermes::EventProducer, :with_application_prefix do
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
      Class.new(Hermes::BaseEvent) do
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
          timestamp: clock.now.iso8601,
          event_version: 1
        }
      }
    end
    let(:expected_routing_key) { "#WhateverItTakes" }
    let(:clock) do
      Class.new do
        def now
          Time.new(2018, 1, 1, 12, 0, 0, 0)
        end
      end.new
    end
    let(:properties) do
      {
        properties: true
      }
    end
    let(:properties_with_headers) do
      properties.merge(headers: headers)
    end
    let(:headers) do
      {
        "X-B3-TraceId" => "5354b4aee6ec3db2a9d0d0f5e54cba5d07127ac662c61289d223c52e3aa5a00d",
        "X-B3-ParentSpanId" => nil,
        "X-B3-SpanId" => "5354b4aee6ec3db2a9d0d0f5e54cba5d07127ac662c6128;YXBwX3ByZWZpeA==",
        "X-B3-Sampled" => "",
        "service" => "app_prefix"
      }
    end
    let(:options) do
      {
        options: true
      }
    end

    before do
      Hermes.configuration.clock = clock
      Hermes.configuration.adapter = :in_memory

      allow(SecureRandom).to receive(:hex) { "5354b4aee6ec3db2a9d0d0f5e54cba5d07127ac662c61289d223c52e3aa5a00d" }
    end

    around do |example|
      VCR.use_cassette("Hermes::EventProducer") do
        example.run
      end
    end

    context "when properties/options are passed" do
      subject(:publish) { producer.publish(event, properties, options) }

      it "produces and publishes event using the right routing key and passed properties with headers and options" do
        publish

        expect(publisher.store).to eq [
          {
            routing_key: expected_routing_key,
            payload: expected_event_payload,
            options: options,
            properties: properties_with_headers
          }
        ]
      end
    end

    context "when properties/options are not passed" do
      subject(:publish) { producer.publish(event) }

      it "produces and publishes event using the right routing key using default dependencies" do
        publish
        expect(publisher.store).to eq [
          {
            routing_key: expected_routing_key,
            payload: expected_event_payload,
            properties: { headers: headers }
          }
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
      Class.new(Hermes::BaseEvent) do
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
        properties: true
      }
    end
    let(:properties_with_headers) do
      properties.merge(headers: headers)
    end
    let(:headers) do
      {
        "X-B3-TraceId" => "5354b4aee6ec3db2a9d0d0f5e54cba5d07127ac662c61289d223c52e3aa5a00d",
        "X-B3-ParentSpanId" => nil,
        "X-B3-SpanId" => "5354b4aee6ec3db2a9d0d0f5e54cba5d07127ac662c6128;YXBwX3ByZWZpeA==",
        "X-B3-Sampled" => "",
        "service" => "app_prefix"
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

    before do
      allow(SecureRandom).to receive(:hex).with(32) { "5354b4aee6ec3db2a9d0d0f5e54cba5d07127ac662c61289d223c52e3aa5a00d" }
    end

    context "when properties/options are passed" do
      subject(:publish) { producer.publish(event, properties, options) }

      it "produces and publishes event using the right routing key using default dependencies" do
        publish

        expect(publisher.store).to eq [
          {
            routing_key: expected_routing_key,
            payload: expected_event_payload,
            properties: properties_with_headers,
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
          {
            routing_key: expected_routing_key,
            payload: expected_event_payload,
            properties: { headers: headers }
          }
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
