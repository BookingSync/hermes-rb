module Hermes
  class TraceContext
    attr_reader :origin_event_headers
    private     :origin_event_headers

    def initialize(origin_event_headers = {})
      @origin_event_headers = origin_event_headers.to_h
    end

    def trace
      @trace ||= origin_event_headers.fetch("X-B3-TraceId", SecureRandom.hex(32))
    end

    def span
      [trace[0..last_trace_index_for_span], ";", encoded_service].join
    end

    def parent_span
      origin_event_headers.fetch("X-B3-SpanId", nil)
    end

    def service
      Hermes.configuration.application_prefix or raise "missing application prefix!"
    end

    private

    def encoded_service
      @encoded_service ||= Base64.strict_encode64(service)
    end

    # expected length is 64, so the maximum index will be 63
    # - 1 due to the semicolon
    def last_trace_index_for_span
      63 - 1 - encoded_service.size
    end
  end
end
