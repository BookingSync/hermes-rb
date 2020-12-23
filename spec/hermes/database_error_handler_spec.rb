RSpec.describe Hermes::DatabaseErrorHandler do
  describe "#call" do
    subject(:call) { handler.call(error) }

    let(:handler) { described_class.new(error_notification_service: error_notification_service) }
    let(:error_notification_service) do
      Class.new do
        attr_reader :error

        def capture_exception(error)
          @error = error
        end
      end.new
    end
    let(:error) { double(:error) }

    it "uses :error_notification_service to capture exception" do
      expect {
        call
      }.to change { error_notification_service.error }.from(nil).to(error)
    end
  end
end
