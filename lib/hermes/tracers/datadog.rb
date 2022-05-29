require "ddtrace"

module Hermes
  module Tracers
    class Datadog
      attr_reader :klass
      private     :klass

      def initialize(klass)
        @klass = klass
      end

      def handle(message)
        tracer = ::Datadog.respond_to?(:tracer) ? ::Datadog.tracer : Datadog::Tracing

        tracer.trace(klass.class.name, service: "hermes", span_type: "rabbitmq") do
          klass.process(message)
        end
      end
    end
  end
end
