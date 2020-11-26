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
end
