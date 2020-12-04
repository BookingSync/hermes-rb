module Hermes
  class Configuration
    attr_accessor :adapter, :clock, :hutch, :application_prefix,
                  :background_processor, :enqueue_method, :event_handler, :rpc_call_timeout,
                  :instrumenter

    def configure_hutch
      yield hutch
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

    def self.configure
      yield configuration
    end

    def logger
      @logger ||= Hermes::Logger.new
    end

    class HutchConfig
      attr_accessor :uri
    end
    private_constant :HutchConfig
  end
end
