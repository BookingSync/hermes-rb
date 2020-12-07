RSpec.describe Hermes::DistributedTraceRepository, :with_application_prefix do
  describe "#create" do
    subject(:create) { repository.create(event) }

    class Events
    end
    class Events::Payment
    end
    class Events::Payment::Created < Hermes::BaseEvent
      attribute :payment_id, Types::Strict::Integer
    end

    let(:repository) do
      described_class.new(config: config, distributed_trace_database: distributed_trace_database)
    end
    let(:config) do
      double(:config, store_distributed_traces?: store_distributed_traces)
    end
    let(:event) do
      Events::Payment::Created.new(payment_id: 1).tap do |current_event|
        current_event.origin_headers = { "X-B3-SpanId" => "parent-span-123" }
      end
    end
    let(:trace_context) do
      double(:trace_context, trace: "trace", span: "span", parent_span: "parent_span", service: "service")
    end
    let(:distributed_trace_database) do
      Class.new do
        attr_reader :attributes

        def create!(attributes)
          @attributes = attributes
        end
      end.new
    end

    context "when it should store distributed traces" do
      let(:store_distributed_traces) { true }
      let(:expected_attributes) do
        {
          trace: "c1b84b37d8a8aa78dc04536c321c1af05a57a57ff4b45e6598da22acc345fcb6",
          span: "c1b84b37d8a8aa78dc04536c321c1af05a57a57ff4b45e6;YXBwX3ByZWZpeA==",
          parent_span: "parent-span-123",
          service: "app_prefix",
          event_class: "Events::Payment::Created",
          routing_key: "payment.created",
          event_body: { "payment_id" => 1 },
          event_headers: {
            "X-B3-TraceId" => "c1b84b37d8a8aa78dc04536c321c1af05a57a57ff4b45e6598da22acc345fcb6",
            "X-B3-ParentSpanId" => "parent-span-123",
            "X-B3-SpanId" => "c1b84b37d8a8aa78dc04536c321c1af05a57a57ff4b45e6;YXBwX3ByZWZpeA==",
            "X-B3-Sampled"=> "",
            "service"=>"app_prefix"
          }
        }
      end

      before do
        allow(SecureRandom).to receive(:hex).with(32) { "c1b84b37d8a8aa78dc04536c321c1af05a57a57ff4b45e6598da22acc345fcb6" }
      end

      it { is_expected_block.to change { distributed_trace_database.attributes }.from(nil).to(expected_attributes) }
    end

    context "when it should not store distributed traces" do
      let(:store_distributed_traces) { false }

      it { is_expected_block.not_to change { distributed_trace_database.attributes } }
    end
  end
end
