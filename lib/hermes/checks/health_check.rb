module Hermes
  module Checks
    class HealthCheck
      def self.check
        broker = Hutch::Broker.new
        broker.connect
        broker.disconnect
        ""
      rescue StandardError => e
        "[Hermes - #{e.message}] "
      end
    end
  end
end
