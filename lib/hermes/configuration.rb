module Hermes
  class Configuration
    attr_accessor :adapter, :clock, :hutch, :application_prefix, :logger,
      :background_processor, :enqueue_method, :event_handler, :rpc_call_timeout,
      :instrumenter, :distributed_tracing_database_uri, :distributed_tracing_database_table,
      :distributes_tracing_mapper, :database_error_handler, :error_notification_service, :producer_error_handler,
      :producer_error_handler_job_class, :producer_retryable, :logger_params_filter

    def configure_hutch
      yield hutch
      hutch.commit_config
    end

    def self.configure
      yield configuration
    end

    def rpc_call_timeout
      @rpc_call_timeout || 10
    end

    def instrumenter
      @instrumenter || Hermes::NullInstrumenter
    end

    def hutch
      @hutch ||= HutchConfig.new
    end

    def logger
      @logger ||= Hermes::Logger.new
    end

    def store_distributed_traces?
      !!distributed_tracing_database_uri
    end

    def distributed_tracing_database_table
      @distributed_tracing_database_table || "hermes_distributed_traces"
    end

    def distributes_tracing_mapper=(mapper)
      raise ArgumentError.new("mapper must respond to :call method") if !mapper.respond_to?(:call)
      @distributes_tracing_mapper = mapper
    end

    def distributes_tracing_mapper
      @distributes_tracing_mapper || Hermes::DistributedTrace::Mapper.new
    end

    def error_notification_service
      @error_notification_service || Hermes::NullErrorNotificationService
    end

    def database_error_handler
      @database_error_handler || Hermes::DatabaseErrorHandler.new(error_notification_service: error_notification_service)
    end

    def producer_error_handler
      @producer_error_handler || Hermes::ProducerErrorHandler::NullHandler
    end

    def producer_retryable
      @producer_retryable || Hermes::Retryable.new(times: 3, errors: [StandardError])
    end

    def enable_safe_producer(producer_error_handler_job_class)
      self.producer_error_handler_job_class = producer_error_handler_job_class

      @producer_error_handler = Hermes::ProducerErrorHandler::SafeHandler.new(
        job_class: producer_error_handler_job_class,
        error_notifier: error_notification_service,
        retryable: producer_retryable
      )
    end

    def logger_params_filter
      @logger_params_filter || Hermes::Logger::ParamsFilter.new
    end

    class HutchConfig
      attr_reader :original_hutch_config
      private     :original_hutch_config

      attr_accessor :uri, :force_publisher_confirms, :enable_http_api_use

      def initialize(original_hutch_config: Hutch::Config)
        @original_hutch_config = original_hutch_config
      end

      def commit_config
        original_hutch_config.set(:tracer, Hutch::Tracers::NewRelic) if Object.const_defined?("NewRelic")
        original_hutch_config.set(:force_publisher_confirms, force_publisher_confirms)
        original_hutch_config.set(:uri, uri)
      end

      def force_publisher_confirms
        return @force_publisher_confirms if defined?(@force_publisher_confirms)

        @force_publisher_confirms ||= true
      end

      def enable_http_api_use
        return @enable_http_api_use if defined?(@enable_http_api_use)

        @enable_http_api_use ||= false
      end
    end
    private_constant :HutchConfig
  end
end
