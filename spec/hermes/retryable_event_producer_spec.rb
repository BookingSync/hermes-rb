RSpec.describe Hermes::RetryableEventProducer, :with_application_prefix do
  describe ".publish", :freeze_time do
    subject(:publish) do
      described_class.publish(event.class.to_s, event.as_json, event.origin_headers)
    end

    let(:publisher) { Hermes::Publisher.instance.current_adapter }
    let(:body) { { "id" => 11 } }
    let(:origin_headers) do
      {
        "X-B3-TraceId" => "5354b4aee6ec3db2a9d0d0f5e54cba5d07127ac662c61289d223c52e3aa5a00d",
        "X-B3-ParentSpanId" => nil,
        "X-B3-SpanId" => "5354b4aee6ec3db2;app_prefix;8f49e235-87e0-40b0-9d28-64398d6541ee",
        "X-B3-Sampled" => "",
        "service" => "app_prefix"
      }
    end
    let(:expected_headers) do
      {
        "X-B3-TraceId" => "5354b4aee6ec3db2a9d0d0f5e54cba5d07127ac662c61289d223c52e3aa5a00d",
        "X-B3-ParentSpanId" => nil,
        "X-B3-SpanId" => "5354b4aee6ec3db2;app_prefix;d51a9023-7743-489d-be3e-dd1808aec36f",
        "X-B3-Sampled" => "",
        "service" => "app_prefix"
      }
    end
    let(:config) { Hermes.configuration }
    let(:event) { EventForRetryableEventProducerTest.from_body_and_headers(body, origin_headers) }

    class EventForRetryableEventProducerTest < Hermes::BaseEvent
      attribute :id, Types::Strict::Integer
    end

    let(:expected_routing_key) { "event_for_retryable_event_producer_test" }
    let(:clock) { Time }
    let(:expected_message_payload) do
      {
        "id" => 11,
        meta: {
          timestamp: clock.now.iso8601,
          event_version: 1
        }
      }
    end


    before do
      allow(SecureRandom).to receive(:uuid) { "d51a9023-7743-489d-be3e-dd1808aec36f" }
    end

    around do |example|
      original_clock = config.clock
      original_adapter = config.adapter

      Hermes.configure do |configuration|
        configuration.clock = clock
        configuration.adapter = :in_memory
      end

      example.run

      Hermes.configure do |configuration|
        configuration.clock = original_clock
        configuration.adapter = original_adapter
      end
    end

    it "publishes event" do
      publish

      expect(publisher.store).to eq [
        {
          routing_key: expected_routing_key,
          payload: expected_message_payload,
          properties: { headers: expected_headers }
        }
      ]
    end
  end
end
