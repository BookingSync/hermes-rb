module Hermes
  class EventProcessor
    extend Forwardable

    def self.call(event_class, body, headers)
      new(
        distributed_trace_repository: Hermes::DistributedTraceRepository.new(config: Hermes.configuration,
          distributed_trace_database: Hermes::DistributedTrace)
      ).call(event_class, body, headers)
    end

    attr_reader :distributed_trace_repository, :config
    private     :distributed_trace_repository, :config

    def initialize(distributed_trace_repository:, config: Hermes.configuration)
      @distributed_trace_repository = distributed_trace_repository
      @config = config
    end

    def call(event_class, body, headers)
      event = Object.const_get(event_class).from_body_and_headers(body, headers)
      instrumenter.instrument("Hermes.EventProcessor.#{event_class}") do
        response = infer_handler(event_class).call(event)
        distributed_trace_repository.create(event)
        ProcessingResult.new(event, response)
      end
    end

    private

    def_delegators :config, :instrumenter, :event_handler

    def infer_handler(event_class)
      event_handler.registration_for(event_class).handler
    end

    ProcessingResult = Struct.new(:event, :response)
  end
end
