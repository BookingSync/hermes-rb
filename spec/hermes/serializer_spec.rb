require "spec_helper"

RSpec.describe Hermes::Serializer do
  describe "#serialize" do
    subject(:serialize) { serializer.serialize(event_payload, version) }

    let(:serializer) do
      Hermes::Serializer.new(correlation_uuid_generator: correlation_uuid_generator, clock: clock)
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
    let(:event_payload) do
      {
        bookingsync: true
      }
    end
    let(:version) { 1 }
    let(:expected_serialized_payload) do
      {
        bookingsync: true,
        meta: {
          timestamp: "2018-01-01T12:00:00+00:00",
          correlation_uuid: "#WhateverItTakes",
          event_version: 1
        }
      }
    end

    it { is_expected.to eq expected_serialized_payload }
  end
end
