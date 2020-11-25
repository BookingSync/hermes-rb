require "hutch"

module Hermes
  class Publisher::HutchAdapter
    def self.connect(configuration: Hermes.configuration.hutch)
      Hutch::Config.set(:uri, configuration.uri)
      Hutch::Config.set(:force_publisher_confirms, true)
      Hutch::Config.set(:tracer, Hutch::Tracers::NewRelic) if Object.const_defined?("NewRelic")
      Hutch.connect(enable_http_api_use: false)
    end

    def initialize(configuration: Hermes.configuration.hutch)
      self.class.connect(configuration: configuration)
    end

    def publish(routing_key, payload, properties = {}, options = {})
      instrumenter.instrument("Hermes.Publisher.HutchAdapter.publish") do
        Hutch.publish(routing_key, payload, properties, options)
      end
      logger.log_published(routing_key, payload, clock.now)
    end

    private

    def instrumenter
      config.instrumenter
    end

    def logger
      config.logger
    end

    def clock
      config.clock
    end

    def config
      Hermes.configuration
    end
  end
end
