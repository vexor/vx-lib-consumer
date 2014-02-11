require 'bunny'
require 'thread'

module Vx
  module Consumer
    class Session

      include Instrument

      @@session_lock  = Mutex.new

      @@shutdown_lock = Mutex.new
      @@shutdown      = ConditionVariable.new
      @@live          = false

      attr_reader :conn

      def shutdown
        @@shutdown_lock.synchronize do
          @@live = false
          @@shutdown.broadcast
        end
      end

      def live?
        @@live
      end

      def resume
        @@live = true
      end

      def wait_shutdown(timeout = nil)
        @@shutdown_lock.synchronize do
          @@shutdown.wait(@@shutdown_lock, timeout)
          not live?
        end
      end

      def close
        if open?
          @@session_lock.synchronize do
            instrument("closing_collection", info: conn_info)

            instrument("close_collection", info: conn_info) do
              begin
                conn.close
                while conn.status != :closed
                  sleep 0.01
                end
              rescue Bunny::ChannelError, Bunny::ClientTimeout => e
                Consumer.exception_handler(e, {})
              end
            end
            @conn = nil
          end
        end
      end

      def open(options = {})
        return self if open?

        @@session_lock.synchronize do
          unless open?
            resume

            @conn ||= Bunny.new(
              nil,       # from ENV['RABBITMQ_URL']
              heartbeat: Consumer.configuration.heartbeat,
              automatically_recover: false
            )

            instrumentation = { info: conn_info }.merge(options)

            instrument("start_connecting", instrumentation)

            instrument("connect", instrumentation) do
              conn.start
              while conn.connecting?
                sleep 0.01
              end
            end
          end
        end

        self
      end

      def open?
        conn && conn.open? && conn.status == :open
      end

      def conn_info
        if conn
          "amqp://#{conn.user}@#{conn.host}:#{conn.port}/#{conn.vhost}"
        else
          "not connected"
        end
      end

      def with_channel
        assert_connection_is_open

        conn.with_channel { |ch| yield ch }
      end

      def declare_exchange(ch, name, options = nil)
        assert_connection_is_open

        options  ||= {}
        ch.exchange name, options
      end

      def declare_queue(ch, name, options = nil)
        assert_connection_is_open

        options ||= {}
        ch.queue name, options
      end

      private

        def assert_connection_is_open
          open? || raise(ConnectionDoesNotExistError)
        end

        def config
          Consumer.configuration
        end

    end
  end
end
