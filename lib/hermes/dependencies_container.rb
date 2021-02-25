module Hermes
  class DependenciesContainer
    def self.[](name)
      public_send(name)
    end

    def self.serializer
      Hermes::Serializer.new
    end

    def self.config
      Hermes.configuration
    end

    def self.hutch_config
      config.hutch
    end

    def self.hutch
      Hutch
    end

    def self.publisher
      Hermes::Publisher.instance
    end

    def self.clock
      config.clock
    end

    def self.logger
      config.logger
    end

    def self.instrumenter
      config.instrumenter
    end

    def self.distributed_trace_repository
      Hermes::DistributedTraceRepository.new(
        config: config,
        distributed_trace_database: Hermes::DistributedTrace,
        distributes_tracing_mapper: distributes_tracing_mapper,
        database_error_handler: database_error_handler
      )
    end

    def self.distributes_tracing_mapper
      config.distributes_tracing_mapper
    end

    def self.event_producer
      Hermes::EventProducer
    end

    def self.event_processor
      Hermes::EventProcessor
    end

    def self.global_store
      RequestStore.store
    end

    def self.database_error_handler
      config.database_error_handler
    end

    def self.producer_error_handler
      config.producer_error_handler
    end

    def self.producer_retryable
      config.producer_retryable
    end

    def self.hutch_logger
      Hutch.logger
    end

    def self.logger_params_filter
      config.logger_params_filter
    end

    def self.objects_resolver
      Object
    end

    def self.consumer_builder
      Hermes::ConsumerBuilder.new
    end
  end
end
