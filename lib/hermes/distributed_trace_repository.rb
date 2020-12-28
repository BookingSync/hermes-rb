module Hermes
  class DistributedTraceRepository
    attr_reader :config, :distributed_trace_database, :distributes_tracing_mapper, :database_error_handler
    private     :config, :distributed_trace_database, :distributes_tracing_mapper, :database_error_handler

    def initialize(config:, distributed_trace_database:, distributes_tracing_mapper:, database_error_handler:)
      @config = config
      @distributed_trace_database = distributed_trace_database
      @distributes_tracing_mapper = distributes_tracing_mapper
      @database_error_handler = database_error_handler
    end

    def create(event)
      if config.store_distributed_traces?
        attributes = attributes_for_trace_context(event, event.trace_context)
        store_trace(attributes)
      end
    end

    private

    def attributes_for_trace_context(event, trace_context)
      distributes_tracing_mapper.call(
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

    def store_trace(attributes)
      distributed_trace_database.create!(attributes)
    rescue StandardError => error
      database_error_handler.call(error)
    end
  end
end
