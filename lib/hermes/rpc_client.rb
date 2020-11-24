module Hermes
  class RpcClient
    DIRECT_REPLY_TO = "amq.rabbitmq.reply-to".freeze

    extend Forwardable

    attr_reader :publisher

    def self.call(event)
      new.call(event)
    end

    attr_reader :broker, :config, :lock, :condition, :response, :rpc_call_timeout, :consumer, :connection
    private     :broker, :config, :lock, :condition, :response, :rpc_call_timeout, :consumer, :connection

    def initialize(publisher: Hermes::Publisher.instance,
    config: Hermes.configuration, rpc_call_timeout: nil)
      @config = config
      @broker = Hutch::Broker.new
      instrumenter.instrument("Hermes.RpcClient.broker_connect") do
        @connection = broker.open_connection
      end
      @lock = Mutex.new
      @condition = ConditionVariable.new
      @rpc_call_timeout = rpc_call_timeout || config.rpc_call_timeout
      @consumer = Bunny::Consumer.new(channel, DIRECT_REPLY_TO, SecureRandom.uuid)
      consumer.on_delivery do |_, _, received_payload|
        handle_delivery(received_payload)
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
              persistence: false
            }
            topic_exchange.publish(event.as_json.to_json, options)
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
      response && JSON.parse(response) or raise RpcTimeoutError
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

    def handle_delivery(payload)
      @response = payload
      lock.synchronize { condition.signal }
    end

    def close_connection
      instrumenter.instrument("Hermes.RpcClient.close_connection") do
        channel.close
        connection.close
      end
    end

    class RpcTimeoutError < StandardError
    end
  end
end
