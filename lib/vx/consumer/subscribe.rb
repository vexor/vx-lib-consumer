module Vx
  module Consumer
    module Subscribe

      def subscribe(options = {})
        ch, q = bind(options)

        subscriber = Subscriber.new(
          ch,
          q,
          ch.generate_consumer_tag,
          !params.ack
        )
        subscriber.vx_consumer_name = params.consumer_name
        subscriber.queue_name       = q.name

        subscriber.on_delivery do |delivery_info, properties, payload|
          handle_delivery ch, delivery_info, properties, payload
        end

        q.subscribe_with(subscriber)
      end

      def handle_delivery(channel, delivery_info, properties, payload)
        payload = decode_payload properties, payload

        instrumentation = {
          consumer:   params.consumer_name,
          payload:    payload,
          properties: properties,
          channel:    channel.id
        }

        with_middlewares :sub, instrumentation do
          instrument("start_processing", instrumentation)
          instrument("process", instrumentation) do
            allocate_pub_channel do
              run_instance delivery_info, properties, payload, channel
            end
          end
        end
      end

      def run_instance(delivery_info, properties, payload, channel)
        new.tap do |inst|
          inst.properties    = properties
          inst.delivery_info = delivery_info
          inst._channel      = channel
        end.perform payload
      end

      private

        def decode_payload(properties, payload)
          Serializer.unpack(properties[:content_type], payload, params.model)
        end

        def bind(options = {})
          qname = options[:queue] || params.queue_name

          instrumentation = {
            consumer: params.consumer_name
          }

          session.open

          ch = session.conn.create_channel
          session.assign_error_handlers_to_channel(ch)
          ch.prefetch configuration.prefetch

          x = session.declare_exchange ch, params.exchange_name, params.exchange_options
          q = session.declare_queue ch, qname, params.queue_options

          instrumentation.merge!(
            exchange:         x.name,
            queue:            q.name,
            queue_options:    params.queue_options,
            exchange_options: params.exchange_options,
            bind:             params.bind_options
          )
          instrument("bind_queue", instrumentation) do
            q.bind(x, params.bind_options)
          end

          [ch, q]
        end

    end
  end
end
