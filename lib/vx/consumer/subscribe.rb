module Vx
  module Consumer
    module Subscribe

      def subscribe
        ch, q = bind
        bunny_consumer = q.subscribe(block: false, ack: params.ack) do |delivery_info, properties, payload|
          payload = decode_payload properties, payload

          instrumentation = {
            consumer:   params.consumer_name,
            payload:    payload,
            properties: properties,
          }

          with_middlewares :sub, instrumentation do
            instrument("start_processing", instrumentation)
            instrument("process", instrumentation) do
              run_instance delivery_info, properties, payload, ch
            end
          end
        end

        Subscriber.new(bunny_consumer)
      end

      def run_instance(delivery_info, properties, payload, channel)
        new.tap do |inst|
          inst.properties    = properties
          inst.delivery_info = delivery_info
          inst.channel       = channel
        end.perform payload
      end

      private

        def decode_payload(properties, payload)
          Serializer.unpack(properties[:content_type], payload, params.model)
        end

        def bind

          instrumentation = {
            consumer: params.consumer_name
          }

          session.open

          ch = session.conn.create_channel
          assign_error_handlers_to_channel(ch)
          ch.prefetch configuration.prefetch

          x = session.declare_exchange ch, params.exchange_name, params.exchange_options
          q = session.declare_queue ch, params.queue_name, params.queue_options

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

        def assign_error_handlers_to_channel(ch)
          ch.on_uncaught_exception {|e, c| Consumer.exception_handler(e, consumer: c) }
          ch.on_error {|e, c| Consumer.exception_handler(e, consumer: c) }
        end

    end
  end
end
