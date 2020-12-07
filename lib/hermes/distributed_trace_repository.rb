module Hermes
  class DistributedTraceRepository
    attr_reader :config, :distributed_trace_database
    private     :config, :distributed_trace_database

    def initialize(config:, distributed_trace_database:)
      @config = config
      @distributed_trace_database = distributed_trace_database
    end

    def create(event)
      if config.store_distributed_traces?
        trace_context = event.trace_context

        distributed_trace_database.create!(
          trace: trace_context.trace,
          span: trace_context.span,
          parent_span: trace_context.parent_span,
          service: trace_context.service,
          event_class: event.class.to_s,
          routing_key: event.routing_key,
          event_body: event.as_json,
          event_headers: event.to_headers
        )
      end
    end
  end
end
