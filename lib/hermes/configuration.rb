module Hermes
  class Configuration
    attr_accessor :adapter, :clock, :hutch, :application_prefix, :logger,
      :background_processor, :enqueue_method, :event_handler, :rpc_call_timeout,
      :instrumenter, :distributed_tracing_database_uri, :distributed_tracing_database_table

    def configure_hutch
      yield hutch
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

    class HutchConfig
      attr_accessor :uri
    end
    private_constant :HutchConfig
  end
end
