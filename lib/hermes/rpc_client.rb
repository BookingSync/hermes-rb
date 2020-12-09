module Hermes
  class RpcClient
    DIRECT_REPLY_TO = "amq.rabbitmq.reply-to".freeze

    extend Forwardable

    attr_reader :publisher

    def self.call(event)
      new.call(event)
    end

    attr_reader :broker, :config, :distributed_trace_repository, :lock, :condition,
      :response_body, :response_headers, :rpc_call_timeout, :consumer, :connection
    private     :broker, :config, :distributed_trace_repository, :lock, :condition,
      :response_body, :response_headers, :rpc_call_timeout, :consumer, :connection

    def initialize(publisher: Hermes::DependenciesContainer["publisher"],
    config: Hermes::DependenciesContainer["config"],
    distributed_trace_repository: Hermes::DependenciesContainer["distributed_trace_repository"],
    rpc_call_timeout: nil)
      @config = config
      @distributed_trace_repository = distributed_trace_repository
      @broker = Hutch::Broker.new
      instrumenter.instrument("Hermes.RpcClient.broker_connect") do
        @connection = broker.open_connection
      end
      @lock = Mutex.new
      @condition = ConditionVariable.new
      @rpc_call_timeout = rpc_call_timeout || config.rpc_call_timeout
      @consumer = Bunny::Consumer.new(channel, DIRECT_REPLY_TO, SecureRandom.uuid)
      consumer.on_delivery do |_delivery_info, metadata, received_payload|
        handle_delivery(metadata[:headers].to_h, received_payload)
      end
    end

    def call(event)
      begin
        instrumenter.instrument("Hermes.RpcClient.call") do
          channel.basic_consume_with(consumer)

          lock.synchronize do
            options = {
              routing_key: event.routing_key,
              reply_to: DIRECT_REPLY_TO,
              persistence: false,
              headers: event.to_headers
            }
            topic_exchange.publish(event.as_json.to_json, options)
            distributed_trace_repository.create(event)
            condition.wait(lock, rpc_call_timeout)
          end
        end
      rescue StandardError => error
        close_connection
        raise error
      ensure
        consumer.cancel if connection.open?
      end

      close_connection
      handle_response
    end

    private

    def_delegators :config, :instrumenter

    def channel
      @channel ||= connection.create_channel
    end

    def default_exchange
      @default_exchange ||= channel.default_exchange
    end

    def topic_exchange
      @topic_exchange ||= channel.topic(Hutch::Config.mq_exchange, durable: true)
    end

    def handle_delivery(headers, payload)
      @response_headers = headers
      @response_body = JSON.parse(payload)
      lock.synchronize { condition.signal }
    end

    def close_connection
      instrumenter.instrument("Hermes.RpcClient.close_connection") do
        channel.close
        connection.close
      end
    end

    def handle_response
      if response_body
        distributed_trace_repository.create(response_event)
        response_body
      else
        raise RpcTimeoutError
      end
    end

    def response_event
      ResponseEvent.new(response_body: response_body).tap do |event|
        event.origin_headers = response_headers
        event.origin_body = response_body
      end
    end

    class RpcTimeoutError < StandardError
    end

    class ResponseEvent < Hermes::BaseEvent
      attribute :response_body, Dry.Types::Nominal::Hash
    end
  end
end
