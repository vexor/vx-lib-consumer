require 'vx/common/rack/builder'

module Vx
  module Consumer
    class Configuration

      attr_accessor :default_exchange_options, :default_queue_options,
        :default_publish_options, :default_exchange_type, :pool_timeout,
        :heartbeat, :spawn_attempts, :content_type, :instrumenter, :debug,
        :on_error, :builders, :prefetch

      def initialize
        reset!
      end

      def debug?
        ENV['VX_CONSUMER_DEBUG']
      end

      def use(target, middleware, *args)
        @builders[target].use middleware, *args
      end

      def on_error(&block)
        @on_error = block if block
        @on_error
      end

      def reset!
        @default_exchange_type = :topic
        @pool_timeout          = 0.5
        @heartbeat             = :server

        @spawn_attempts        = 1

        @content_type          = 'application/json'
        @prefetch              = 1

        @instrumenter          = nil
        @on_error              = ->(e, env){ nil }

        @builders = {
          pub: Vx::Common::Rack::Builder.new,
          sub: Vx::Common::Rack::Builder.new
        }

        @default_exchange_options = {
          durable:     true,
          auto_delete: false
        }

        @default_queue_options = {
          durable:      true,
          auto_delete:  false,
          exclusive:    false
        }

        @default_publish_options = {
        }
      end

    end
  end
end
