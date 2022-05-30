RSpec.describe Hermes::Tracers::Datadog do
  describe "#handle" do
    subject(:handle) { tracer.handle(message) }

    let(:tracer) { described_class.new(klass) }
    let(:klass)  do
      Class.new do
        attr_reader :message

        def initialize
          @message = nil
        end

        def class
          OpenStruct.new(name: "ClassName")
        end

        def process(message)
          @message = message
        end
      end.new
    end
    let(:message) { double(:message) }
    let(:dd_tracer) do
      if defined?(DDTrace)
        Datadog::Tracing
      else
        Datadog.tracer
      end
    end

    before do
      allow(dd_tracer).to receive(:trace).and_call_original
    end

    it "uses Datadog tracer" do
      handle

      expect(dd_tracer).to have_received(:trace).with("ClassName",
        hash_including(service: "hermes", span_type: "rabbitmq"))
    end

    it "processes the message" do
      expect {
        handle
      }.to change { klass.message }.from(nil).to(message)
    end
  end
end
