require "spec_helper"

RSpec.describe "Event Producer Integration With In MemoryPublisher", :freeze_time, :with_application_prefix do
  describe "publishing" do
    subject(:publish) { Hermes::EventProducer.build.publish(event) }

    let(:event) do
      Class.new(Hermes::BaseEvent) do
        def as_json
          {
            message: "bookingsync + rabbit = :hearts:"
          }
        end

        def routing_key
          "bookingsync"
        end

        def version
          1
        end
      end.new
    end
    let(:adapter) { Hermes::Publisher.instance.current_adapter }
    let(:expected_store_content) do
      [
        {
          routing_key: "bookingsync",
          payload: {
            message: "bookingsync + rabbit = :hearts:",
            meta: {
              timestamp: clock.now.iso8601,
              correlation_uuid: correlation_uuid_generator.uuid,
              event_version: 1
            }
          },
          properties: {
            headers: {
              "X-B3-TraceId" => "cca9d9fc4e33e58aca38f0c14bd3e39a5690fc9d8b9acded5f5636980d86d68d",
              "X-B3-ParentSpanId" => nil,
              "X-B3-SpanId" => "cca9d9fc4e33e58aca38f0c14bd3e39a5690fc9d8b9acde;YXBwX3ByZWZpeA==",
              "X-B3-Sampled" => "",
              "service"=>"app_prefix"
            }
          }
        }
      ]
    end
    let(:correlation_uuid_generator) do
      Class.new do
        def uuid
          "#WhateverItTakes"
        end
      end.new
    end
    let(:clock) do
      Class.new do
        def now
          Time.new(2018, 1, 1, 12, 0, 0, 0)
        end
      end.new
    end

    before do
      in_memory_publisher = Hermes::Publisher::InMemoryAdapter.new
      Hermes::Publisher.instance.current_adapter = in_memory_publisher
      Hermes.configuration.clock = clock
      Hermes.configuration.correlation_uuid_generator = correlation_uuid_generator

      allow(SecureRandom).to receive(:hex) { "cca9d9fc4e33e58aca38f0c14bd3e39a5690fc9d8b9acded5f5636980d86d68d" }
    end

    it "publishes messages that can be consumed by the other consumer with a proper payload" do
      publish

      expect(adapter.store).to eq expected_store_content
    end
  end
end
