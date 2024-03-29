RSpec.describe Hermes::DistributedTraceRepository, :with_application_prefix do
  describe "#create" do
    subject(:create) { repository.create(event) }

    class Events
    end
    class Events::Payment
    end
    class Events::Payment::Created < Hermes::BaseEvent
      attribute :payment_id, Types::Strict::Integer
      attribute :secret, Types::Strict::String
    end

    let(:repository) do
      described_class.new(
        config: config,
        distributed_trace_database: distributed_trace_database,
        distributes_tracing_mapper: distributes_tracing_mapper,
        database_error_handler: database_error_handler
      )
    end
    let(:config) do
      double(:config, store_distributed_traces?: store_distributed_traces)
    end
    let(:event) do
      Events::Payment::Created.new(payment_id: 1, secret: "secret").tap do |current_event|
        current_event.origin_headers = { "X-B3-SpanId" => "parent-span-123" }
      end
    end
    let(:distributed_trace_database) do
      Class.new do
        attr_reader :attributes

        def create!(attributes)
          @attributes = attributes
        end
      end.new
    end
    let(:distributes_tracing_mapper) do
      Hermes::DistributedTrace::Mapper.new
    end
    let(:database_error_handler) do
      Hermes::DatabaseErrorHandler.new(error_notification_service: error_notification_service)
    end
    let(:error_notification_service) do
      Class.new do
        attr_reader :error

        def capture_exception(error)
          @error = error
        end
      end.new
    end

    before do
      allow(SecureRandom).to receive(:uuid) { "c288d2c7-6903-4825-8aec-c3fcc2aa0045" }
    end

    context "when it should store distributed traces" do
      let(:store_distributed_traces) { true }
      let(:expected_attributes) do
        {
          trace: "c1b84b37d8a8aa78dc04536c321c1af05a57a57ff4b45e6598da22acc345fcb6",
          span: "c1b84b37d8a8aa78;app_prefix;c288d2c7-6903-4825-8aec-c3fcc2aa0045",
          parent_span: "parent-span-123",
          service: "app_prefix",
          event_class: "Events::Payment::Created",
          routing_key: "payment.created",
          event_body: { "payment_id" => 1, "secret" => "[STRIPPED]" },
          event_headers: {
            "X-B3-TraceId" => "c1b84b37d8a8aa78dc04536c321c1af05a57a57ff4b45e6598da22acc345fcb6",
            "X-B3-ParentSpanId" => "parent-span-123",
            "X-B3-SpanId" => "c1b84b37d8a8aa78;app_prefix;c288d2c7-6903-4825-8aec-c3fcc2aa0045",
            "X-B3-Sampled"=> "",
            "service"=>"app_prefix"
          }
        }
      end

      before do
        allow(SecureRandom).to receive(:hex).with(32) { "c1b84b37d8a8aa78dc04536c321c1af05a57a57ff4b45e6598da22acc345fcb6" }
      end

      context "on success" do
        it { is_expected_block.to change { distributed_trace_database.attributes }.from(nil).to(expected_attributes) }
      end

      context "on error" do
        before do
          allow(distributed_trace_database).to receive(:create!) { raise error }
        end

        let(:error) { StandardError.new("something went wrong") }

        it { is_expected_block.not_to change { distributed_trace_database.attributes } }
        it { is_expected_block.not_to raise_error }
        it { is_expected_block.to change { error_notification_service.error }.from(nil).to(error) }
      end
    end

    context "when it should not store distributed traces" do
      let(:store_distributed_traces) { false }

      it { is_expected_block.not_to change { distributed_trace_database.attributes } }
    end
  end
end
