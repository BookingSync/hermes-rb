RSpec.describe Hermes::TraceContext do
  describe "#trace" do
    subject(:trace) { trace_context.trace }

    context "when X-B3-TraceId is present in origin_event_headers" do
      let(:trace_context) { described_class.new(origin_event_headers) }
      let(:origin_event_headers) do
        {
          "X-B3-TraceId" => "123abc"
        }
      end

      it { is_expected.to eq "123abc" }
    end

    context "when X-B3-TraceId is not present in origin_event_headers" do
      let(:trace_context) { described_class.new }

      before do
        allow(SecureRandom).to receive(:hex).with(32).and_return("2a13a84617048f29b734377b43aace1211af3acf6165346b18022d1ab7a94c7c")
      end

      it { is_expected.to eq "2a13a84617048f29b734377b43aace1211af3acf6165346b18022d1ab7a94c7c" }

      it "has a length of 64" do
        expect(trace.size).to eq 64
      end
    end
  end

  describe "#span" do
    subject(:span) { trace_context.span }

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

    context "when X-B3-TraceId is present in origin_event_headers" do
      let(:trace_context) { described_class.new(origin_event_headers) }
      let(:origin_event_headers) do
        {
          "X-B3-TraceId" => "2a13a84617048f29b734377b43aace1211af3acf6165346b18022d1ab7a94c7c"
        }
      end

      it { is_expected.to eq "2a13a84617048f29b734377b43aace1211af3acf6165346;YXBwX3ByZWZpeA==" }

      it "has a length of 64" do
        expect(span.size).to eq 64
      end
    end

    context "when X-B3-TraceId is not present in origin_event_headers" do
      let(:trace_context) { described_class.new }

      before do
        allow(SecureRandom).to receive(:hex).with(32).and_return("2a13a84617048f29b734377b43aace1211af3acf6165346b18022d1ab7a94c7c")
      end

      it { is_expected.to eq "2a13a84617048f29b734377b43aace1211af3acf6165346;YXBwX3ByZWZpeA==" }

      it "has a length of 64" do
        expect(span.size).to eq 64
      end
    end
  end

  describe "#parent_span" do
    subject(:parent_span) { trace_context.parent_span }

    context "when X-B3-SpanId is present in origin_event_headers" do
      let(:trace_context) { described_class.new(origin_event_headers) }
      let(:origin_event_headers) do
        {
          "X-B3-SpanId" => "123abc"
        }
      end

      it { is_expected.to eq "123abc" }
    end

    context "when X-B3-SpanId is not present in origin_event_headers" do
      let(:trace_context) { described_class.new }

      it { is_expected.to eq nil }
    end
  end

  describe "#service" do
    subject(:service) { described_class.new.service }

    context "when application prefix is set" do
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

      it { is_expected.to eq "app_prefix" }
    end

    context "when application prefix is not set" do
      around do |example|
        original_application_prefix = Hermes.configuration

        Hermes.configure do |config|
          config.application_prefix = nil
        end

        example.run

        Hermes.configure do |config|
          config.application_prefix = original_application_prefix
        end
      end

      it { is_expected_block.to raise_error "missing application prefix!" }
    end
  end
end
