require "spec_helper"

RSpec.describe Hermes::PublisherFactory do
  describe ".build" do
    subject(:build) { Hermes::PublisherFactory.build(adapter) }

    context "for :hutch adapter" do
      let(:adapter) { :hutch }

      around do |example|
        VCR.use_cassette("Hermes::PublisherFactory") do
          example.run
        end
      end

      it { is_expected.to be_a(Hermes::Publisher::HutchAdapter) }
    end

    context "for :in_memory adapter" do
      let(:adapter) { :in_memory }

      it { is_expected.to be_a(Hermes::Publisher::InMemoryAdapter) }
    end

    context "for other value adapter" do
      let(:adapter) { :bookingsync }

      it { is_expected_block.to raise_error "invalid async messaging adapter: bookingsync" }
    end
  end
end
