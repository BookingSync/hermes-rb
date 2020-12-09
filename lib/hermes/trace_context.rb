module Hermes
  class TraceContext
    attr_reader :origin_event_headers
    private     :origin_event_headers

    DELIMITER = ";".freeze
    SPAN_LENGTH = 64
    private_constant :DELIMITER, :SPAN_LENGTH

    def initialize(origin_event_headers = {})
      @origin_event_headers = origin_event_headers.to_h
    end

    def trace
      @trace ||= origin_event_headers.fetch("X-B3-TraceId", SecureRandom.hex(32))
    end

    def span
      @span ||= [trace[0..last_trace_index_for_span], DELIMITER, service_seed_for_span, DELIMITER, uuid].join
    end

    def parent_span
      origin_event_headers.fetch("X-B3-SpanId", nil)
    end

    def service
      Hermes.configuration.application_prefix or raise "missing application prefix!"
    end

    private

    def service_seed_for_span
      service[0..14]
    end

    def uuid
      @uuid ||= SecureRandom.uuid
    end

    # expected length is 64, so the maximum index will be 63
    # - 1 due to the semicolon
    # - 1 due to the semicolon
    def last_trace_index_for_span
      (64 - 1) - 1 - service_seed_for_span.size - 1 - uuid.size
    end
  end
end
