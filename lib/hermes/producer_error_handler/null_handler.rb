module Hermes
  module ProducerErrorHandler
    class NullHandler
      def self.call(*)
        yield
      end
    end
  end
end
