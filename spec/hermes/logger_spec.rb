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
    subject(:log_enqueued) { logger.log_enqueued(event_class, body, headers, timestamp) }

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
    let(:headers) do
      { header: "true" }
    end
    let(:timestamp) { "01-01-2020 12:00:00" }
    let(:expected_result) do
      [
        "[Hutch] enqueued: Event Class, headers: #{headers}, body: #{stripped_body} at 01-01-2020 12:00:00"
      ]
    end

    context "with default params filter" do
      let(:stripped_body) do
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

      it "logs that a job was enqueued and strips sensitive info" do
        expect {
          log_enqueued
        }.to change { logger_backend.registry }.from([]).to(expected_result)
      end

      it "does not modify original body" do
        expect {
          log_enqueued
        }.not_to change { body[:access_token] }
      end
    end

    context "with custom params filter" do
      let(:custom_params_filter) do
        ->(_key, value) { value.gsub!(value, "[removed]") if value.is_a?(String) }
      end
      let(:stripped_body) do
        {
          access_token: "[removed]",
          refresh_token: "[removed]",
          account_id: 5,
          credit_card_number: "[removed]",
          password: "[removed]",
          password_confirmation: "[removed]",
          currency: "[removed]"
        }
      end

      around do |example|
        original_params_filter = Hermes.configuration.logger_params_filter

        Hermes.configure do |config|
          config.logger_params_filter = custom_params_filter
        end

        example.run

        Hermes.configure do |config|
          config.logger_params_filter = original_params_filter
        end
      end

      it "logs that a job was enqueued and strips sensitive info" do
        expect {
          log_enqueued
        }.to change { logger_backend.registry }.from([]).to(expected_result)
      end

      it "does not modify original body" do
        expect {
          log_enqueued
        }.not_to change { body[:access_token] }
      end
    end
  end

  describe "#log_published" do
    subject(:log_published) { logger.log_published(routing_key, payload, properties, timestamp) }

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
    let(:properties) do
      { header: "true" }
    end
    let(:timestamp) { "01-01-2020 12:00:00" }
    let(:expected_result) do
      [
        "[Hutch] published event to: hermes.routing.key, properties: #{properties}, body: #{stripped_body} at 01-01-2020 12:00:00"
      ]
    end

    context "with default params filter" do
      let(:stripped_body) do
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

      it "logs that an event was published and strips sensitive info" do
        expect {
          log_published
        }.to change { logger_backend.registry }.from([]).to(expected_result)
      end

      it "does not modify original body" do
        expect {
          log_published
        }.not_to change { payload[:access_token] }
      end
    end

    context "with custom params filter" do
      let(:custom_params_filter) do
        ->(_key, value) { value.gsub!(value, "[removed]") if value.is_a?(String) }
      end
      let(:stripped_body) do
        {
          access_token: "[removed]",
          refresh_token: "[removed]",
          account_id: 5,
          credit_card_number: "[removed]",
          password: "[removed]",
          password_confirmation: "[removed]",
          currency: "[removed]"
        }
      end

      around do |example|
        original_params_filter = Hermes.configuration.logger_params_filter

        Hermes.configure do |config|
          config.logger_params_filter = custom_params_filter
        end

        example.run

        Hermes.configure do |config|
          config.logger_params_filter = original_params_filter
        end
      end

      it "logs that a job was enqueued and strips sensitive info" do
        expect {
          log_published
        }.to change { logger_backend.registry }.from([]).to(expected_result)
      end

      it "does not modify original body" do
        expect {
          log_published
        }.not_to change { payload[:access_token] }
      end
    end
  end

  describe "#log_health_check_failure" do
    subject(:log_health_check_failure) { logger.log_health_check_failure(error) }

    let(:error) { "could not connect" }
    let(:expected_result) { ["[Hermes] health check failed: could not connect"] }

    it "logs health check failure" do
      expect {
        log_health_check_failure
      }.to change { logger_backend.registry }.from([]).to(expected_result)
    end
  end
end
