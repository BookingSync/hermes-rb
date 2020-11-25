require "hermes/publisher/hutch_adapter"
require "hermes/publisher/in_memory_adapter"


module Hermes
  class PublisherFactory
    def self.build(adapter)
      case adapter
        when :hutch
          Hermes::Publisher::HutchAdapter.new
        when :in_memory
          Hermes::Publisher::InMemoryAdapter.new
        else
          raise "invalid async messaging adapter: #{adapter}"
      end
    end
  end
end
