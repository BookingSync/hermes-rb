RSpec.describe Hermes::ProducerErrorHandler::SafeHandler do
  describe "#call" do
    let(:safe_handler) do
      described_class.new(
        job_class: job_class, error_notifier: error_notifier, retryable: retryable
      )
    end
    let(:job_class) do
      Class.new do
        attr_reader :event_class_name, :origin_body, :origin_headers

        def enqueue(event_class_name, origin_body, origin_headers)
          @event_class_name = event_class_name
          @origin_body = origin_body
          @origin_headers = origin_headers
        end
      end.new
    end
    let(:error_notifier) do
      Class.new do
        attr_reader :error

        def initialize
          @error = OpenStruct.new(message: nil)
        end

        def capture_exception(error)
          @error = error
        end
      end.new
    end
    let(:retryable) do
      Class.new do
        def self.perform
          yield
        end
      end
    end
    let(:event) do
      EventForSafeHandlerTest.from_body_and_headers({ "id" => 1 }, { "X-B3-TraceId" => "trace" })
    end

    class EventForSafeHandlerTest < Hermes::BaseEvent
      attribute :id, Types::Strict::Integer
    end

    context "when there is an error" do
      subject(:call) { safe_handler.call(event) { raise StandardError.new("whoops") } }

      it "captures exception" do
        expect {
          call
        }.to change { error_notifier.error.message }.to("whoops")
      end

      it "enqueues recovery job class" do
        expect {
          call
        }.to change { job_class.event_class_name }.to("EventForSafeHandlerTest")
        .and change { job_class.origin_body }.to("id" => 1)
        .and change { job_class.origin_headers }.to("X-B3-TraceId" => "trace")
      end

      it "rescues form the exception" do

        expect {
          call
        }.not_to raise_error
      end
    end

    context "when there is no error" do
      subject(:call) { safe_handler.call(event) { "block" } }

      before do
        allow(error_notifier).to receive(:capture_exception).and_call_original
        allow(job_class).to receive(:enqueue).and_call_original
      end

      it "does not capture any exception" do
        call

        expect(error_notifier).not_to have_received(:capture_exception)
      end

      it "does not enqueue any job" do
        call

        expect(job_class).not_to have_received(:enqueue)
      end

      it "executes the logic" do
        counter = 0

        safe_handler.call(event) do
          counter += 1
        end

        expect(counter).to eq 1
      end
    end
  end
end
