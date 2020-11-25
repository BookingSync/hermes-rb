module Hermes
  class EventProducer
    extend Forwardable

    attr_reader :publisher, :serializer, :config
    private     :publisher, :serializer, :config

    def self.publish(event, properties = {}, options = {})
      build.publish(event, properties, options)
    end

    def self.build
      correlation_uuid_generator = Hermes.configuration.correlation_uuid_generator
      new(
        publisher: Hermes::Publisher.instance,
        serializer: Hermes::Serializer.new(correlation_uuid_generator: correlation_uuid_generator),
        config: Hermes.configuration
      )
    end

    def initialize(publisher:, serializer:, config: Hermes.configuration)
      @publisher = publisher
      @serializer = serializer
      @config = config
    end

    def publish(event, properties = {}, options = {})
      instrumenter.instrument("Hermes.EventProducer.publish") do
        publisher.publish(event.routing_key, serialize(event.as_json, event.version), properties, options)
      end
    end

    private

    def_delegators :config, :instrumenter

    def serialize(payload, version)
      serializer.serialize(payload, version)
    end
  end
end
