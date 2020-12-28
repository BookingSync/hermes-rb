RSpec.describe Hermes::NullErrorNotificationService do
  describe ".capture_exception" do
    subject(:capture_exception) { described_class.capture_exception(error) }

    let(:error) { double(:error) }

    it "does nothing" do
      capture_exception
    end
  end
end
