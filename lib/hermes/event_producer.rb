module Hermes
  class EventProducer
    extend Forwardable

    attr_reader :publisher, :serializer, :distributed_trace_repository, :config
    private     :publisher, :serializer, :distributed_trace_repository, :config

    def self.publish(event, properties = {}, options = {})
      build.publish(event, properties, options)
    end

    def self.build
      new(
        publisher: Hermes::DependenciesContainer["publisher"],
        serializer: Hermes::DependenciesContainer["serializer"],
        distributed_trace_repository: Hermes::DependenciesContainer["distributed_trace_repository"],
        config: Hermes::DependenciesContainer["config"]
      )
    end

    def initialize(publisher:, serializer:, distributed_trace_repository:, config:)
      @publisher = publisher
      @serializer = serializer
      @distributed_trace_repository = distributed_trace_repository
      @config = config
    end

    def publish(event, properties = {}, options = {})
      publish_event(event, properties, options).tap { store_trace(event) }
    end

    private

    def_delegators :config, :instrumenter

    def serialize(payload, version)
      serializer.serialize(payload, version)
    end

    def publish_event(event, properties = {}, options = {})
      instrumenter.instrument("Hermes.EventProducer.publish") do
        event.origin_headers ||= Hermes.origin_headers

        publisher.publish(
          event.routing_key,
          serialize(event.as_json, event.version),
          properties.merge(headers: event.to_headers),
          options
        )
      end
    end

    def store_trace(event)
      instrumenter.instrument("Hermes.EventProducer.store_trace") do
        distributed_trace_repository.create(event)
      end
    end
  end
end
