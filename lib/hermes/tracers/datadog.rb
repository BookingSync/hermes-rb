begin
 require "datadog"
rescue LoadError
  require "ddtrace"
end

module Hermes
  module Tracers
    class Datadog
      attr_reader :klass
      private     :klass

      def initialize(klass)
        @klass = klass
      end

      def handle(message)
        tracer = ::Datadog.respond_to?(:tracer) ? ::Datadog.tracer : "Datadog::Tracing".safe_constantize

        tracer.trace(
          klass.class.name || klass.class.to_s,
          service: "hermes",
          span_type_key => "rabbitmq"
        ) do
          klass.process(message)
        end
      end

      private

      def span_type_key
        if defined?(DDTrace)
          :span_type
        else
          :type
        end
      end
    end
  end
end
