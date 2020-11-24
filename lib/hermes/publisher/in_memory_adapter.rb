module Hermes
  class Publisher::InMemoryAdapter
    attr_reader :store

    def self.connect
    end

    def initialize
      @store = []
    end

    def publish(routing_key, payload, properties = {}, options = {})
      message = { routing_key: routing_key, payload: payload }
      message[:properties] = properties if properties.any?
      message[:options] = options if options.any?

      @store << message
    end
  end
end
