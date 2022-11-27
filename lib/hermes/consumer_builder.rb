require "hutch"

module Hermes
  class ConsumerBuilder
    def build(event_class, consumer_config: -> {})
      queue = queue_name_from_event(event_class)
      routing_key = event_class.routing_key
      consumer_name = consumer_name_from_event(event_class)

      consumer = Class.new do
        include ::Hutch::Consumer

        consume routing_key
        queue_name queue
        instance_exec(&consumer_config)

        define_method :process do |message|
          instrumenter.instrument("Hermes.Consumer.process") do
            body = message.body
            headers = message.properties[:headers].to_h

            registration = config.event_handler.registration_for(event_class)

            if registration.async?
              config.background_processor.public_send(config.enqueue_method, event_class.to_s, body, headers)
              logger.log_enqueued(event_class, body, headers, config.clock.now)
            else
              ensure_database_connection!
              result = event_processor.call(event_class.to_s, body, headers)
              event = result.event
              response = result.response

              if registration.rpc?
                message.delivery_info.channel.default_exchange.publish(
                  response.to_json,
                  routing_key: message.properties.reply_to,
                  correlation_id: message.properties.correlation_id,
                  headers: event.to_headers
                )
              end
            end
          end
        end

        private

        def instrumenter
          Hermes::DependenciesContainer["instrumenter"]
        end

        def logger
          Hermes::DependenciesContainer["logger"]
        end

        def config
          Hermes::DependenciesContainer["config"]
        end

        def event_processor
          Hermes::DependenciesContainer["event_processor"]
        end

        def ensure_database_connection!
          config.database_connection_provider.reconnect! if config.database_connection_provider
        end
      end

      register_consumer(consumer_name, consumer)
      Object.const_get(consumer_name)
    end

    private

    def queue_name_from_event(event)
      "#{config.application_prefix}.#{event.routing_key}.queue"
    end

    def consumer_name_from_event(event)
      "#{event}HutchConsumer".gsub("::", "_")
    end

    def register_consumer(consumer_name, consumer)
      if !Object.const_defined?(consumer_name)
        Object.const_set(consumer_name, consumer)
      end
    end

    def config
      Hermes::DependenciesContainer["config"]
    end
  end
end
