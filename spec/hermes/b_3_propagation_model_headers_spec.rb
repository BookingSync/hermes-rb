RSpec.describe Hermes::B3PropagationModelHeaders do
  describe ".trace_id_key" do
    subject(:trace_id_key) { Hermes::B3PropagationModelHeaders.trace_id_key }

    it { is_expected.to eq "X-B3-TraceId" }
  end

  describe ".span_id_key" do
    subject(:span_id_key) { Hermes::B3PropagationModelHeaders.span_id_key }

    it { is_expected.to eq "X-B3-SpanId" }
  end

  describe ".parent_span_id_key" do
    subject(:parent_span_id_key) { Hermes::B3PropagationModelHeaders.parent_span_id_key }

    it { is_expected.to eq "X-B3-ParentSpanId" }
  end

  describe ".sampled_key" do
    subject(:sampled_key) { Hermes::B3PropagationModelHeaders.sampled_key }

    it { is_expected.to eq "X-B3-Sampled" }
  end

  describe "#as_json" do
    subject(:as_json) { described_class.new(trace_context).as_json }

    let(:trace_context) { double(:trace_context, trace: "123", span: "abc", parent_span: "zxc") }
    let(:expected_result) do
      {
        "X-B3-TraceId" => "123",
        "X-B3-ParentSpanId" => "zxc",
        "X-B3-SpanId" => "abc",
        "X-B3-Sampled" => ""
      }
    end

    it { is_expected.to eq expected_result }
  end

  describe "#to_h" do
    subject(:to_h) { described_class.new(trace_context).to_h }

    let(:trace_context) { double(:trace_context, trace: "123", span: "abc", parent_span: "zxc") }
    let(:expected_result) do
      {
        "X-B3-TraceId" => "123",
        "X-B3-ParentSpanId" => "zxc",
        "X-B3-SpanId" => "abc",
        "X-B3-Sampled" => ""
      }
    end

    it { is_expected.to eq expected_result }
  end
end
