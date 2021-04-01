module Hermes
  class Logger
    attr_reader :backend, :logger_params_filter
    private     :backend, :logger_params_filter

    def initialize(backend: Hermes::DependenciesContainer["hutch_logger"],
    logger_params_filter: Hermes::DependenciesContainer["logger_params_filter"])
      @backend = backend
      @logger_params_filter = logger_params_filter
    end

    def log_enqueued(event_class, body, headers, timestamp)
      backend.info "[Hutch] enqueued: #{event_class}, headers: #{headers}, body: #{strip_sensitive_info(body)} at #{timestamp}"
    end

    def log_published(routing_key, body, properties, timestamp)
      backend.info "[Hutch] published event to: #{routing_key}, properties: #{properties}, body: #{strip_sensitive_info(body)} at #{timestamp}"
    end

    def log_health_check_failure(error)
      backend.info "[Hermes] health check failed: #{error}"
    end

    private

    def strip_sensitive_info(body)
      body.deep_dup.tap do |body_copy|
        body_copy.each { |key, value| logger_params_filter.call(key, value) }
      end
    end
  end
end
