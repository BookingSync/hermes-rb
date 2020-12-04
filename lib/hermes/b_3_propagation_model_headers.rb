module Hermes
  class B3PropagationModelHeaders
    attr_reader :trace_context
    private     :trace_context

    def initialize(trace_context)
      @trace_context = trace_context
    end

    def as_json
      to_h
    end

    def to_h
      {
        "X-B3-TraceId" => trace_context.trace,
        "X-B3-ParentSpanId" => trace_context.parent_span,
        "X-B3-SpanId" => trace_context.span,
        "X-B3-Sampled" => ""
      }
    end
  end
end
