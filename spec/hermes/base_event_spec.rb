RSpec.describe Hermes::BaseEvent do
  class Events
  end
  class Events::Payment
  end
  class Events::Payment::MarkedAsPaid < Hermes::BaseEvent
    attribute :payment_id, Types::Strict::Integer
    attribute :cents, Types::Strict::Integer
    attribute :currency, Types::Strict::String
  end

  class Payment
  end
  class Payment::MarkedAsPaid < Hermes::BaseEvent
    attribute :payment_id, Types::Strict::Integer
    attribute :cents, Types::Strict::Integer
    attribute :currency, Types::Strict::String
  end

  let(:example_event_class) { Payment::MarkedAsPaid }
  let(:event) { example_event_class.new(attributes) }
  let(:attributes) do
    {
      payment_id: 1,
      cents: 100,
      currency: "EUR"
    }
  end

  describe "initialization" do
    it "raises error when any of the param is missing" do
      expect {
        example_event_class.new(payment_id: 1)
      }.to raise_error /:cents is missing/
    end
  end

  describe ".from_body_and_headers" do
    subject(:from_body_and_headers) do
      example_event_class.from_body_and_headers(body, headers)
    end

    let(:body) { attributes.stringify_keys }
    let(:headers) do
      {
        header: "value"
      }
    end

    it "initializes event with assigning origin_body and origin_headers" do
      expect(from_body_and_headers).to be_instance_of example_event_class
      expect(from_body_and_headers.payment_id).to eq 1
      expect(from_body_and_headers.cents).to eq 100
      expect(from_body_and_headers.currency).to eq "EUR"
      expect(from_body_and_headers.origin_body).to eq body
      expect(from_body_and_headers.origin_headers).to eq headers
    end
  end

  describe ".routing_key" do
    subject(:routing_key) { example_event_class.routing_key }

    context "when event class is scoped by Events namespace" do
      let(:example_event_class) { Events::Payment::MarkedAsPaid }

      it { is_expected.to eq "payment.marked_as_paid" }
    end

    context "when event class is not scoped by Events namespace" do
      it { is_expected.to eq "payment.marked_as_paid" }
    end
  end

  describe "#routing_key" do
    subject(:routing_key) { event.routing_key }

    context "when event class is scoped by Events namespace" do
      let(:example_event_class) { Events::Payment::MarkedAsPaid }

      it { is_expected.to eq "payment.marked_as_paid" }
    end

    context "when event class is not scoped by Events namespace" do
      it { is_expected.to eq "payment.marked_as_paid" }
    end
  end

  describe "#as_json" do
    subject(:as_json) { event.as_json }

    let(:expected_hash) do
      {
        "payment_id" => 1,
        "cents" => 100,
        "currency" => "EUR"
      }
    end

    it { is_expected.to eq expected_hash }
  end

  describe "#version" do
    subject(:version) { event.version }

    it { is_expected.to eq 1 }
  end

  describe "origin_body" do
    subject(:origin_body) { event.origin_body }

    context "when it's not set" do
      it { is_expected.to eq nil }
    end

    context "when it's set" do
      let(:message) do
        {
          message: "body"
        }
      end

      before do
        event.origin_body = message
      end

      it { is_expected.to eq message }
    end
  end

  describe "origin_headers" do
    subject(:origin_headers) { event.origin_headers }

    context "when it's not set" do
      it { is_expected.to eq nil }
    end

    context "when it's set" do
      let(:headers) do
        {
          example: "header"
        }
      end

      before do
        event.origin_headers = headers
      end

      it { is_expected.to eq headers }
    end
  end

  describe "#to_headers" do
    subject(:to_headers) { event.to_headers }

    around do |example|
      original_application_prefix = Hermes.configuration

      Hermes.configure do |config|
        config.application_prefix = "app_prefix"
      end

      example.run

      Hermes.configure do |config|
        config.application_prefix = original_application_prefix
      end
    end

    context "when origin headers are set" do
      let(:trace_id) { "8f5d7272fa0fef3e060889edd33198adf1b17d854254343ae5053eb403eccf43" }
      let(:origin_headers) do
        {
          "X-B3-TraceId" => trace_id,
          "X-B3-ParentSpanId" => nil,
          "X-B3-SpanId" => "123-abc-123",
          "X-B3-Sampled" => ""
        }
      end
      let(:headers) do
        {
          "X-B3-TraceId" => trace_id,
          "X-B3-ParentSpanId" => "123-abc-123",
          "X-B3-SpanId" => "8f5d7272fa0fef3e060889edd33198adf1b17d854254343;YXBwX3ByZWZpeA==",
          "X-B3-Sampled" => "",
          "service" => "app_prefix"
        }
      end

      before do
        event.origin_headers = origin_headers
      end

      it { is_expected.to eq headers }
    end

    context "when origin headers are not set" do
      let(:trace_id) { "840b519a3da037686c2bee33ea5fce629c02de77ac48300c61c2fe94f398d10f" }

      before do
        allow(SecureRandom).to receive(:hex) { trace_id }
      end

      let(:headers) do
        {
          "X-B3-TraceId" => trace_id,
          "X-B3-ParentSpanId" => nil,
          "X-B3-SpanId" => "840b519a3da037686c2bee33ea5fce629c02de77ac48300;YXBwX3ByZWZpeA==",
          "X-B3-Sampled" => "",
          "service" => "app_prefix"
        }
      end

      it { is_expected.to eq headers }
    end
  end
end
