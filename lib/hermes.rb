require "hermes/configuration"
require "hermes/consumer_builder"
require "hermes/event_handler"
require "hermes/event_processor"
require "hermes/event_producer"
require "hermes/publisher"
require "hermes/publisher_factory"
require "hermes/serializer"
require "hermes/rpc_client"
require "hermes/null_instrumenter"
require "hermes/logger"
require "hermes/rb"

module Hermes
  def self.configuration
    @configuration ||= Hermes::Configuration.new
  end

  def self.configure
    yield configuration
  end
end
