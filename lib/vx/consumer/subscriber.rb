require 'thread'
require 'bunny/consumer'

module Vx
  module Consumer
    class Subscriber < Bunny::Consumer

      include Instrument

      attr_accessor :vx_consumer_name

      def initialize(*args)
        super(*args)
        @lock = Mutex.new
      end

      def graceful_shutdown
        instrument('graceful_shutdown_consumer', consumer: vx_consumer_name)
        in_progress { cancel }
      end

      def in_progress
        @lock.synchronize do
          yield
        end
      end

      def running?
        @lock.locked?
      end

      def call(*args)
        in_progress do
          @on_delivery.call(*args) if @on_delivery
        end
      end

      def cancel
        instrument('cancel_consumer', consumer: vx_consumer_name)
        super
        channel.close unless channel.closed?
      end

      def join
        channel.work_pool.join
      end

      def wait_shutdown
        Thread.new do
          Thread.current.abort_on_exception = true
          Consumer.wait_shutdown
          cancel
        end
      end

    end
  end
end
