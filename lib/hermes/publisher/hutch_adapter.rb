require "hutch"

module Hermes
  class Publisher::HutchAdapter
    def self.connect(configuration: Hermes::DependenciesContainer["hutch_config"])
      Hutch.connect(enable_http_api_use: configuration.enable_http_api_use)
    end

    def initialize(configuration: Hermes::DependenciesContainer["hutch_config"])
      self.class.connect(configuration: configuration)
    end

    def publish(routing_key, payload, properties = {}, options = {})
      instrumenter.instrument("Hermes.Publisher.HutchAdapter.publish") do
        Hermes::DependenciesContainer["hutch"].publish(routing_key, payload, properties, options)
      end
      logger.log_published(routing_key, payload, properties, clock.now)
    end

    private

    def instrumenter
      DependenciesContainer["instrumenter"]
    end

    def logger
      DependenciesContainer["logger"]
    end

    def clock
      DependenciesContainer["clock"]
    end
  end
end
