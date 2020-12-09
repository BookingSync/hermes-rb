require "hermes/base_event"
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
require "hermes/b_3_propagation_model_headers"
require "hermes/trace_context"
require "hermes/distributed_trace_repository"
require "hermes/dependencies_container"
require "dry/struct"
require "active_support"
require "active_support/core_ext/string"
require "active_record"

module Hermes
  def self.configuration
    @configuration ||= Hermes::Configuration.new
  end

  def self.configure
    yield configuration
  end
end

require "hermes/distributed_trace"
