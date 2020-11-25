RSpec::Matchers.define :publish_async_message do |routing_key|
  supports_block_expectations

  match do |block|
    block.call

    published_messages.find do |message|
      event_payload_from_message = message[:payload].with_indifferent_access.except(:meta)

      message[:routing_key] == routing_key && event_payload_from_message == @event_payload
    end.present?
  end

  failure_message do
    "expected to publish: #{routing_key} event with payload: #{@event_payload} " +
     "all published messages are #{formatted_published_messages}"
  end

  chain :with_event_payload do |event_payload|
    @event_payload = event_payload.with_indifferent_access
  end

  define_method :published_messages do
    Hermes::Publisher.instance.current_adapter.store
  end

  define_method :formatted_published_messages do
    published_messages.join("\n")
  end
end
