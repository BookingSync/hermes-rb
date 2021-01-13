module Hermes
  class RetryableEventProducer
    def self.publish(event_class, event_body, origin_headers)
      new(
        objects_resolver: Hermes::DependenciesContainer["objects_resolver"],
        event_producer: Hermes::DependenciesContainer["event_producer"]
      ).publish(event_class, event_body, origin_headers)
    end

    attr_reader :objects_resolver, :event_producer
    private     :objects_resolver, :event_producer

    def initialize(objects_resolver:, event_producer:)
      @objects_resolver = objects_resolver
      @event_producer = event_producer
    end

    def publish(event_class, event_body, origin_headers)
      event = objects_resolver.const_get(event_class).new(event_body.deep_symbolize_keys)
      event.origin_headers = origin_headers.except(Hermes::B3PropagationModelHeaders.span_id_key)
      event_producer.publish(event)
    end
  end
end
