require "dry-container"

module Hermes
  class EventHandler
    attr_reader :container, :consumer_builder
    private     :container, :consumer_builder

    def initialize(container: Dry::Container.new, consumer_builder: Hermes::DependenciesContainer["consumer_builder"])
      @container = container
      @consumer_builder = consumer_builder
    end

    def handle_events(&block)
      instance_exec(&block)
    end

    def handle(event_class, with:, async: true, rpc: false, consumer_config: -> {})
      handler = with
      options = {
        async: async,
        rpc: rpc,
        consumer_config: consumer_config
      }
      consumer = build_consumer_for_event(event_class, consumer_config)

      Registration.new(handler, consumer, options).tap do |registration|
        container.register(event_class, registration)
      end
    end

    def registration_for(event_class)
      container.resolve(event_class)
    end

    private

    def build_consumer_for_event(event_class, consumer_config)
      consumer_builder.build(event_class, consumer_config: consumer_config)
    end

    class Registration
      attr_reader :handler, :consumer, :options

      def initialize(handler, consumer, options = {})
        @handler = handler
        @consumer = consumer
        @options = options
      end

      def async?
        options.fetch(:async) == true
      end

      def rpc?
        options.fetch(:rpc) == true
      end

      def consumer_config
        optons.fetch(:consumer_config)
      end
    end
  end
end
