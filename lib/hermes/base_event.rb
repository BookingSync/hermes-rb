module Hermes
  class BaseEvent < Dry::Struct
    EVENTS_NAMESPACE = "Events".freeze
    private_constant :EVENTS_NAMESPACE

    attr_accessor :origin_body, :origin_headers

    def self.from_body_and_headers(body, headers)
      new(body.deep_symbolize_keys).tap do |event|
        event.origin_body = body
        event.origin_headers = headers
      end
    end

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

    def to_headers
      Hermes::B3PropagationModelHeaders
        .new(trace_context)
        .as_json
        .merge("service" => trace_context.service)
    end

    def trace_context
      @trace_context ||= Hermes::TraceContext.new(origin_headers)
    end
  end
end
