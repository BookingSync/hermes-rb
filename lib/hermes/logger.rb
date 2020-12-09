module Hermes
  class Logger
    SENSITIVE_ATTRIBUTES_KEYWORDS = %w(token password credit_card).freeze
    STRIPPED_VALUE = "[STRIPPED]".freeze

    private_constant :SENSITIVE_ATTRIBUTES_KEYWORDS, :STRIPPED_VALUE

    attr_reader :backend
    private     :backend

    def initialize(backend: Hutch.logger)
      @backend = backend
    end

    def log_enqueued(event_class, body, headers, timestamp)
      backend.info "[Hutch] enqueued: #{event_class}, headers: #{headers}, body: #{strip_sensitive_info(body)} at #{timestamp}"
    end

    def log_published(routing_key, body, properties, timestamp)
      backend.info "[Hutch] published event to: #{routing_key}, properties: #{properties}, body: #{strip_sensitive_info(body)} at #{timestamp}"
    end

    private

    def strip_sensitive_info(body)
      body.stringify_keys.map do |attribute, value|
        if SENSITIVE_ATTRIBUTES_KEYWORDS.any? { |sensitive_attribute| attribute.match(sensitive_attribute) }
          [attribute, STRIPPED_VALUE]
        else
          [attribute, value]
        end
      end.to_h
    end
  end
end
