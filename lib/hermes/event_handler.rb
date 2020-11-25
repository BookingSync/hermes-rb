require "dry-container"

module Hermes
  class EventHandler
    attr_reader :container, :consumer_builder
    private     :container, :consumer_builder

    def initialize
      @container = Dry::Container.new
      @consumer_builder = Hermes::ConsumerBuilder.new
    end

    def handle_events(&block)
      instance_exec(&block)
    end

    def handle(event_class, with:, async: true, rpc: false)
      handler = with
      options = {
        async: async,
        rpc: rpc
      }
      consumer = build_consumer_for_event(event_class)

      registration = Registration.new(handler, consumer, options)
      container.register(event_class, registration)
    end

    def registration_for(event_class)
      container.resolve(event_class)
    end

    private

    def build_consumer_for_event(event_class)
      consumer_builder.build(event_class)
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
    end
  end
end
