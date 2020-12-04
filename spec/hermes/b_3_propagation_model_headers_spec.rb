RSpec.describe Hermes::B3PropagationModelHeaders do
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
