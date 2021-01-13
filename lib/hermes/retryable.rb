module Hermes
  class Retryable
    attr_reader :times, :errors, :before_retry
    private     :times, :errors, :before_retry

    def initialize(times:, errors: [], before_retry: ->(_error) {})
      @times = times
      @errors = errors
      @before_retry = before_retry
    end

    def perform
      executed = 0
      begin
        executed += 1
        yield
      rescue *errors => error
        if executed < times
          before_retry.call(error)
          retry
        else
          raise error
        end
      end
    end
  end
end
