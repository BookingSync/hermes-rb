module Hermes
  class B3PropagationModelHeaders
    attr_reader :trace_context
    private     :trace_context

    def self.trace_id_key
      "X-B3-TraceId"
    end

    def self.span_id_key
      "X-B3-SpanId"
    end

    def self.parent_span_id_key
      "X-B3-ParentSpanId"
    end

    def self.sampled_key
      "X-B3-Sampled"
    end

    def initialize(trace_context)
      @trace_context = trace_context
    end

    def as_json
      to_h
    end

    def to_h
      {
        self.class.trace_id_key => trace_context.trace,
        self.class.parent_span_id_key => trace_context.parent_span,
        self.class.span_id_key => trace_context.span,
        self.class.sampled_key => ""
      }
    end
  end
end
