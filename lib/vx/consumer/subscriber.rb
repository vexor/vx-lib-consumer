module Vx
  module Consumer
    Subscriber = Struct.new(:consumer) do

      def cancel
        consumer.cancel
        consumer.channel.close unless consumer.channel.closed?
      end

      def join
        consumer.channel.work_pool.join
      end

      def wait
        loop do
          if Consumer.shutdown?
            cancel
            break
          end
          sleep Consumer.configuration.pool_timeout
        end
      end

    end
  end
end
