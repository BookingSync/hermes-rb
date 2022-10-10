require "spec_helper"

RSpec.describe Hermes::Logger::ParamsFilter do
  describe "#call" do
    context "with default config for initialization" do
      subject(:call) { described_class.new.call(attribute, value) }

      let(:value) { "value" }

      context "when value is nil" do
        let(:value) { nil }

        describe "for attributes containing sensitive keyword" do
          let(:attribute) { :access_token }

          it { is_expected_block.not_to change { value } }
        end

        describe "for attributes not containing sensitive keyword" do
          let(:attribute) { :other }

          it { is_expected_block.not_to change { value } }
        end
      end

      context "when value is not nil" do
        describe "for attributes containing 'token' word" do
          let(:attribute) { :access_token }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'password' word" do
          let(:attribute) { :password_confirmation }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'credit_card' word" do
          let(:attribute) { :credit_card }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'card_number' word" do
          let(:attribute) { :card_number }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'card_number' word" do
          let(:attribute) { :card_number }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'verification_value' word" do
          let(:attribute) { :verification_value }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'private_key' word" do
          let(:attribute) { :private_key }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'signature' word" do
          let(:attribute) { :signature }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'api_key' word" do
          let(:attribute) { :api_key }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'secret_key' word" do
          let(:attribute) { :secret_key }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'publishable_key' word" do
          let(:attribute) { :publishable_key }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'client_key' word" do
          let(:attribute) { :client_key }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'client_secret' word" do
          let(:attribute) { :client_secret }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for attributes containing 'secret' word" do
          let(:attribute) { :secret }

          it { is_expected_block.to change { value }.from("value").to("[STRIPPED]") }
        end

        describe "for other attributes" do
          let(:attribute) { :currency }

          it { is_expected_block.not_to change { value } }
        end
      end
    end

    context "with custom config for initialization" do
      subject(:call) { params_filter.call(attribute, value) }

      let(:params_filter) { described_class.new(sensitive_keywords: [:magic_attribute, /^space$/], stripped_value: "[removed]") }
      let(:value) { "value" }

      describe "for 'magic_attribute' word" do
        let(:attribute) { :magic_attribute }

        it { is_expected_block.to change { value }.from("value").to("[removed]") }
      end

      describe "for 'space' word" do
        let(:attribute) { :space }

        it { is_expected_block.to change { value }.from("value").to("[removed]") }
      end

      describe "for 'namespace' word" do
        let(:attribute) { :namespace }

        it { is_expected_block.not_to change { value } }
      end

      describe "for other attributes" do
        let(:attribute) { :password }

        it { is_expected_block.not_to change { value } }
      end
    end
  end
end
