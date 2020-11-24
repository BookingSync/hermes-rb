require "time"

module Hermes
  class Serializer
    attr_reader :correlation_uuid_generator, :clock
    private     :correlation_uuid_generator, :clock

    def initialize(correlation_uuid_generator:, clock: Hermes.configuration.clock)
      @correlation_uuid_generator = correlation_uuid_generator
      @clock = clock
    end

    def serialize(event_payload, version)
      event_payload.merge(meta: build_meta(version))
    end

    private

    def build_meta(version)
      {
        timestamp: clock.now.iso8601,
        correlation_uuid: correlation_uuid_generator.uuid,
        event_version: version
      }
    end
  end
end
