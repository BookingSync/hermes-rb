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
        "X-B3-SpanId" => "5354b4aee6ec3db2;app_prefix;8f49e235-87e0-40b0-9d28-64398d6541ee",
        "X-B3-Sampled" => "",
        "service" => "app_prefix"
      }
    end
    let(:options) do
      {
        options: true
      }
    end
    let(:config) { Hermes.configuration }

    before do
      allow(SecureRandom).to receive(:hex) { "5354b4aee6ec3db2a9d0d0f5e54cba5d07127ac662c61289d223c52e3aa5a00d" }
      allow(SecureRandom).to receive(:uuid) { "8f49e235-87e0-40b0-9d28-64398d6541ee" }
    end

    around do |example|
      original_clock = config.clock
      original_adapter = config.adapter

      Hermes.configure do |configuration|
        configuration.clock = clock
        configuration.adapter = :in_memory
      end

      VCR.use_cassette("Hermes::EventProducer") do
        example.run
      end

      Hermes.configure do |configuration|
        configuration.clock = original_clock
        configuration.adapter = original_adapter
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

      describe "origin headers" do
        let(:published_trace_id) { publisher.store.first[:properties][:headers]["X-B3-TraceId"] }
        let(:published_parent_span) { publisher.store.first[:properties][:headers]["X-B3-ParentSpanId"] }

        context "when origin headers are assigned to the event and they are assigned to Hermes.origin_headers" do
          let(:hermes_origin_headers) do
            {
              "X-B3-TraceId" => hermes_trace_id,
              "X-B3-ParentSpanId" => "zxc",
              "X-B3-SpanId" => "abc",
              "X-B3-Sampled" => ""
            }
          end
          let(:hermes_trace_id) { "123" }
          let(:event_origin_headers) do
            {
              "X-B3-TraceId" => event_trace_id,
              "X-B3-ParentSpanId" => "123098",
              "X-B3-SpanId" => "123abc",
              "X-B3-Sampled" => ""
            }
          end
          let(:event_trace_id) { "qwe" }

          before do
            event.origin_headers = event_origin_headers
            Hermes.origin_headers = hermes_origin_headers
          end

          it "uses event's headers to serialize headers for the first event and it does not modify origin_headers on the event's level" do
            expect {
              publish
            }.not_to change { event.origin_headers }

            expect(published_trace_id).to eq event_trace_id
            expect(published_parent_span).to be_present
          end
        end

        context "when origin headers are not assigned to the event and they are assigned to Hermes.origin_headers" do
          let(:hermes_origin_headers) do
            {
              "X-B3-TraceId" => trace_id,
              "X-B3-ParentSpanId" => "zxc",
              "X-B3-SpanId" => "abc",
              "X-B3-Sampled" => ""
            }
          end
          let(:trace_id) { "123" }

          before do
            Hermes.origin_headers = hermes_origin_headers
          end

          it "uses these headers to serialize headers for the first event and it modifies origin_headers on the event's level" do
            expect {
              publish
            }.to change { event.origin_headers }.from(nil).to(hermes_origin_headers)

            expect(published_trace_id).to eq trace_id
            expect(published_parent_span).to be_present
          end
        end

        context "when origin headers are not assigned to the event and they are not assigned to Hermes.origin_headers" do
          it "just works and it modifies origin_headers on the event's level" do
            expect {
              publish
            }.to change { event.origin_headers }.from(nil).to({})

            expect(published_trace_id).to be_present
            expect(published_parent_span).to eq nil
          end
        end
      end
    end
  end

  describe ".build" do
    subject(:build) { Hermes::EventProducer.build }

    it { is_expected.to be_a(Hermes::EventProducer) }
  end

  describe "#publish" do
    let(:producer) do
      Hermes::EventProducer.new(
        publisher: publisher,
        serializer: serializer,
        distributed_trace_repository: distributed_trace_repository,
        config: config
      )
    end
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
        "X-B3-SpanId" => "5354b4aee6ec3db2;app_prefix;8f49e235-87e0-40b0-9d28-64398d6541ee",
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
    let(:distributed_trace_repository) do
      Class.new do
        attr_reader :event

        def create(event)
          @event = event
        end
      end.new
    end
    let(:config) { Hermes.configuration }

    before do
      allow(SecureRandom).to receive(:hex).with(32) { "5354b4aee6ec3db2a9d0d0f5e54cba5d07127ac662c61289d223c52e3aa5a00d" }
      allow(SecureRandom).to receive(:uuid) { "8f49e235-87e0-40b0-9d28-64398d6541ee" }
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

      it "stores trace" do
        expect {
          publish
        }.to change { distributed_trace_repository.event }.from(nil).to(event)
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

      it "stores trace" do
        expect {
          publish
        }.to change { distributed_trace_repository.event }.from(nil).to(event)
      end
    end

    describe "instrumentation" do
      subject(:publish) { producer.publish(event) }

      it "is instrumented" do
        expect(Hermes.configuration.instrumenter).to receive(:instrument)
          .with("Hermes.EventProducer.publish")
          .and_call_original
        expect(Hermes.configuration.instrumenter).to receive(:instrument)
          .with("Hermes.EventProducer.store_trace")
          .and_call_original

        publish
      end
    end
  end
end
