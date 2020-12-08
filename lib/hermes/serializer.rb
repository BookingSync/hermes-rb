require "time"

module Hermes
  class Serializer
    attr_reader :clock
    private     :clock

    def initialize(clock: Hermes::DependenciesContainer["clock"])
      @clock = clock
    end

    def serialize(event_payload, version)
      event_payload.merge(meta: build_meta(version))
    end

    private

    def build_meta(version)
      {
        timestamp: clock.now.iso8601,
        event_version: version
      }
    end
  end
end
