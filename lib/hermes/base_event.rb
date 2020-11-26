module Hermes
  class BaseEvent < Dry::Struct
    EVENTS_NAMESPACE = "Events".freeze
    private_constant :EVENTS_NAMESPACE

    attr_accessor :preceeding_event

    def self.routing_key
      names = to_s.split("::")
      starting_index = if names.first.include?(EVENTS_NAMESPACE)
        1
      else
        0
      end
      names[starting_index..-1].map(&:underscore).map(&:downcase).join(".")
    end

    def routing_key
      self.class.routing_key
    end

    def version
      1
    end

    def as_json
      to_h.stringify_keys
    end
  end
end
