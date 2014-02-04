require 'securerandom'

module Vx
  module Consumer
    module Publish

      def publish(payload, options)
        session.open

        options ||= {}
        options[:routing_key]  = params.routing_key if params.routing_key && !options.key?(:routing_key)
        options[:headers]      = params.headers     if params.headers && !options.key?(:headers)

        options[:content_type] ||= params.content_type || Consumer.configuration.content_type
        options[:message_id]   ||= SecureRandom.uuid

        name = params.exchange_name

        instrumentation = {
          payload:     payload,
          exchange:    x.name,
          consumer:    params.consumer_name,
          properties:  options,
        }

        instrument("process_publishing", instrumentation) do
          session.with_channel do |ch|
            x = session.declare_exchange ch, name
            x.publish payload, options
          end
        end

      end

    end
  end
end
