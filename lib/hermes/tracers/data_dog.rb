require "ddtrace"

module Hermes
  module Tracers
    class DataDog
      attr_reader :klass
      private     :klass

      def initialize(klass)
        @klass = klass
      end

      def handle(message)
        Datadog.tracer.trace(klass.class.name, service: "hermes", span_type: "rabbitmq") do
          klass.process(message)
        end
      end
    end
  end
end
