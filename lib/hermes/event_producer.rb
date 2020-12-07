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
        publisher: Hermes::Publisher.instance,
        serializer: Hermes::Serializer.new,
        distributed_trace_repository: Hermes::DistributedTraceRepository.new(
          config: Hermes.configuration,
          distributed_trace_database: Hermes::DistributedTrace
        ),
        config: Hermes.configuration
      )
    end

    def initialize(publisher:, serializer:, distributed_trace_repository:, config: Hermes.configuration)
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
