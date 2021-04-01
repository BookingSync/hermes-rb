RSpec.describe Hermes::Checks::HealthCheck do
  describe ".check" do
    subject(:check) { described_class.check }

    context "on success" do
      it "returns a blank string" do
        expect(check).to eq ""
      end
    end

    context "on failure" do
      around do |example|
        original_uri = Hutch::Config.uri
        Hutch::Config.uri = "invalid"

        example.run

        Hutch::Config.uri = original_uri
      end

      it "returns an error message" do
        expect(check).to eq "[Hermes - Connection-level error: NOT_ALLOWED - vhost invalid not found] "
      end
    end
  end
end
