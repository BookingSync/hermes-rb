RSpec.describe "Hermes Safer Producer Integration", :with_application_prefix do
  class EventForTestingIntegrationWithSafeProducer < Hermes::BaseEvent
    attribute :message, Types::Strict::String
  end

  describe "Hutch" do
    subject(:publish) { Hermes::EventProducer.publish(event) }

    let(:event) do
      EventForTestingIntegrationWithSafeProducer.new(message: message).tap do |ev|
        ev.origin_headers = {
          "X-B3-TraceId" => "019283",
          "X-B3-ParentSpanId" => nil,
          "X-B3-SpanId" => "123-abc-123",
          "X-B3-Sampled" => "",
          "service" => "app"
        }
      end
    end
    let(:message) { "safe producer test" }
    let(:clock) do
      Class.new do
        def now
          Time.new(2018, 1, 1, 12, 0, 0, 0)
        end
      end.new
    end
    let(:error_notification_service) do
      Class.new do
        attr_reader :error

        def capture_exception(error)
          @error = error
        end
      end.new
    end
    let(:producer_error_handler_job_class) do
      Class.new do
        attr_reader :event_class_name, :event_body, :origin_headers

        def enqueue(event_class_name, event_body, origin_headers)
          @event_class_name = event_class_name
          @event_body = event_body
          @origin_headers = origin_headers
        end
      end.new
    end
    let(:configuration) { Hermes.configuration }

    before do
      allow(Hermes::Publisher.instance).to receive(:publish) { raise StandardError.new("whoops") }
    end

    around do |example|
      in_memory_publisher = Hermes::Publisher::InMemoryAdapter.new
      Hermes::Publisher.instance.current_adapter = in_memory_publisher

      original_clock = configuration.clock
      original_error_notification_service = configuration.error_notification_service
      original_producer_error_handler = configuration.producer_error_handler
      original_producer_error_handler_job_class = configuration.producer_error_handler_job_class

      Hermes.configure do |config|
        config.clock = clock
        config.error_notification_service = error_notification_service
        config.enable_safe_producer(producer_error_handler_job_class)
      end

      example.run

      Hermes.configure do |config|
        config.clock = original_clock
        config.error_notification_service = original_error_notification_service
        config.producer_error_handler = original_producer_error_handler
        config.producer_error_handler_job_class = original_producer_error_handler_job_class
      end
    end

    it "does not raise error" do
      expect {
        publish
      }.not_to raise_error
    end

    it "enqueues recovery job class" do
      expect {
        publish
      }.to change { producer_error_handler_job_class.event_class_name }.to("EventForTestingIntegrationWithSafeProducer")
      .and change { producer_error_handler_job_class.event_body }.to("message" => message)
      .and change {
        producer_error_handler_job_class.origin_headers
      }.to(hash_including("X-B3-TraceId", "X-B3-SpanId", "X-B3-ParentSpanId", "X-B3-Sampled", "service"))
    end

    it "rescues form the exception" do
      expect {
        publish
      }.not_to raise_error

      expect(error_notification_service.error.message).to eq "whoops"
    end
  end
end
