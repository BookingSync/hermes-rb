RSpec.describe Hermes::DistributedTrace::Mapper do
  describe "#call" do
    subject(:call) { described_class.new.call(attributes) }

    let(:attributes) do
      {
        access_token: "access token",
        refresh_token: "refresh token",
        account_id: 5,
        credit_card_number: "4111-1111-1111-1111",
        password: "password",
        password_confirmation: "password confirmation",
        currency: "EUR"
      }
    end
    let(:sanitized_attributes) do
      {
        access_token: "[STRIPPED]",
        refresh_token: "[STRIPPED]",
        account_id: 5,
        credit_card_number: "[STRIPPED]",
        password: "[STRIPPED]",
        password_confirmation: "[STRIPPED]",
        currency: "EUR"
      }
    end

    it { is_expected.to eq sanitized_attributes }
  end
end
