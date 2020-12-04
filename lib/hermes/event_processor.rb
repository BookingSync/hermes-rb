module Hermes
  class EventProcessor
    extend Forwardable

    def self.call(event_class, body, headers)
      new.call(event_class, body, headers)
    end

    def call(event_class, body, headers)
      event = Object.const_get(event_class).from_body_and_headers(body, headers)

      instrumenter.instrument("Hermes.EventProcessor.#{event_class}") do
        infer_handler(event_class).call(event)
      end
    end

    private

    def_delegators :config, :instrumenter, :event_handler

    def infer_handler(event_class)
      event_handler.registration_for(event_class).handler
    end

    def config
      @config ||= Hermes.configuration
    end
  end
end
