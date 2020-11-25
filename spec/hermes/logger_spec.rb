require "spec_helper"

RSpec.describe Hermes::Logger do
 let(:logger) { described_class.new(backend: logger_backend) }
  let(:logger_backend) do
    Class.new do
      attr_reader :registry

      def initialize
        @registry = []
      end

      def info(log)
        @registry << log
      end
    end.new
  end

  describe "#log_enqueued" do
    subject(:log_enqueued) { logger.log_enqueued(event_class, body, timestamp) }

    let(:event_class) { "Event Class" }
    let(:body) do
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
    let(:timestamp) { "01-01-2020 12:00:00" }

    let(:stripped_body) do
      {
        access_token: "[STRIPPED]",
        refresh_token: "[STRIPPED]",
        account_id: 5,
        credit_card_number: "[STRIPPED]",
        password: "[STRIPPED]",
        password_confirmation: "[STRIPPED]",
        currency: "EUR"
      }.stringify_keys
    end
    let(:expected_result) do
      [
        "[Hutch] enqueued: Event Class with #{stripped_body} at 01-01-2020 12:00:00"
      ]
    end

    it "logs that a job was enqueued and strips sensitive info" do
      expect {
        log_enqueued
      }.to change { logger_backend.registry }.from([]).to(expected_result)
    end
  end

  describe "#log_published" do
    subject(:log_published) { logger.log_published(routing_key, payload, timestamp) }

    let(:routing_key) { "hermes.routing.key" }
    let(:payload) do
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
    let(:timestamp) { "01-01-2020 12:00:00" }
    let(:stripped_body) do
      {
        access_token: "[STRIPPED]",
        refresh_token: "[STRIPPED]",
        account_id: 5,
        credit_card_number: "[STRIPPED]",
        password: "[STRIPPED]",
        password_confirmation: "[STRIPPED]",
        currency: "EUR"
      }.stringify_keys
    end
    let(:expected_result) do
      [
        "[Hutch] published event to: hermes.routing.key with #{stripped_body} at 01-01-2020 12:00:00"
      ]
    end

    it "logs that an event was published and strips sensitive info" do
      expect {
        log_published
      }.to change { logger_backend.registry }.from([]).to(expected_result)
    end
  end
end
