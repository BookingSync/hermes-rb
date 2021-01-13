module Hermes
  module ProducerErrorHandler
    class SafeHandler
      attr_reader :job_class, :error_notifier, :retryable
      private     :job_class, :error_notifier, :retryable

      def initialize(job_class:, error_notifier:, retryable:)
        @job_class = job_class
        @error_notifier = error_notifier
        @retryable = retryable
      end

      def call(event)
        retryable.perform { yield }
      rescue => error
        error_notifier.capture_exception(error)
        job_class.enqueue(event.class.name, event.as_json, event.origin_headers)
      end
    end
  end
end
