require 'securerandom'

module Vx
  module Lib
    module Consumer
      module Publish

        def publish(payload, options = {})
          session.open

          options ||= {}
          options[:routing_key]  = params.routing_key if params.routing_key && !options.key?(:routing_key)
          options[:headers]      = params.headers     if params.headers && !options.key?(:headers)

          options[:content_type] ||= params.content_type || configuration.content_type
          options[:message_id]   ||= SecureRandom.uuid

          name = params.exchange_name

          instrumentation = {
            payload:     payload,
            exchange:    name,
            consumer:    params.consumer_name,
            properties:  options,
          }

          with_middlewares :pub, instrumentation do
            session.with_pub_channel do |ch|
              instrument("process_publishing", instrumentation.merge(channel: ch.id)) do
                encoded = encode_payload(payload, options[:content_type])
                x = session.declare_exchange ch, name, params.exchange_options
                x.publish encoded, options
              end
            end
          end
        end

        private

          def encode_payload(payload, content_type)
            Serializer.pack(content_type, payload)
          end

      end
    end
  end
end
