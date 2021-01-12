RSpec.describe Hermes::ProducerErrorHandler::NullHandler do
  describe ".call" do
    subject(:handler) { described_class }

    it "just yields" do
      counter = 0

      handler.call { counter += 1 }

      expect(counter).to eq 1
    end
  end
end
