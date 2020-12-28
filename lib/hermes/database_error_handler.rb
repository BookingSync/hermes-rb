module Hermes
  class DatabaseErrorHandler
    attr_reader :error_notification_service
    private     :error_notification_service

    def initialize(error_notification_service:)
      @error_notification_service = error_notification_service
    end

    def call(error)
      error_notification_service.capture_exception(error)
    end
  end
end
