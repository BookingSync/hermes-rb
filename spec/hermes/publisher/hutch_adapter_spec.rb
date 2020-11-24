require "spec_helper"

RSpec.describe Hermes::Publisher::HutchAdapter do
  describe ".connect" do
    subject(:connect) { Hermes::Publisher::HutchAdapter.connect }

    around do |example|
      original_value = Hermes.configuration.hutch.uri
      Hermes.configuration.hutch.uri = "amqp://guest:guest@localhost:5672"

      VCR.use_cassette("Hermes::Publisher::HutchAdapter") do
        example.run
      end

      Hermes.configuration.hutch.uri = original_value
    end

    it "initializes Hutch with a proper config" do
      connect

      expect(Hutch::Config.get(:uri)).to eq "amqp://guest:guest@localhost:5672"
      expect(Hutch::Config.get(:force_publisher_confirms)).to eq true
      expect(Hutch).to be_connected
    end
  end

  describe "config" do
    subject(:initialize_hutch) { Hermes::Publisher::HutchAdapter.new }

    around do |example|
      original_value = Hermes.configuration.hutch.uri
      Hermes.configuration.hutch.uri = "amqp://guest:guest@localhost:5672"

      VCR.use_cassette("Hermes::Publisher::HutchAdapter") do
        example.run
      end

      Hermes.configuration.hutch.uri = original_value
    end

    it "has proper config" do
      initialize_hutch

      expect(Hutch::Config.get(:uri)).to eq "amqp://guest:guest@localhost:5672"
      expect(Hutch::Config.get(:force_publisher_confirms)).to eq true
      expect(Hutch).to be_connected
    end
  end

  describe "#publish" do
    let(:publisher) { Hermes::Publisher::HutchAdapter.new }
    let(:routing_key) { "bookingsync" }
    let(:payload) do
      {
        "OneDayYouMay" => true
      }
    end

    around do |example|
      VCR.use_cassette("Hermes::Publisher::HutchAdapter") do
        example.run
      end
    end

    context "when properties/options are provided" do
      subject(:publish) { publisher.publish(routing_key, payload, properties, options) }

      let(:properties) do
        {
          properties: true
        }
      end
      let(:options) do
        {
          options: true
        }
      end

      it "publishes message with a given routing key, properties and options hashes" do
        expect(Hutch).to receive(:publish).with(routing_key, payload, properties, options).and_call_original

        publish
      end
    end

    context "when properties/options are not provided" do
      subject(:publish) { publisher.publish(routing_key, payload) }

      it "publishes message with a given routing key" do
        expect(Hutch).to receive(:publish).with(routing_key, payload, {}, {}).and_call_original

        publish
      end
    end
  end
end
