require 'thread'
require 'bunny/consumer'

module Vx
  module Lib
    module Consumer
      class Subscriber < Bunny::Consumer

        attr_accessor :vx_consumer_name, :queue_name

        def initialize(*args)
          super(*args)
          @lock = Mutex.new
        end

        def graceful_shutdown
          in_progress do
            cancel
          end
        end

        def try_graceful_shutdown
          if @lock.try_lock
            begin
              cancel
            ensure
              @lock.unlock
            end
            true
          else
            false
          end
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
            sleep 0
          end
        end

        def cancel
          unless closed?
            super
            channel.close unless closed?
          end
        end

        def closed?
          channel.closed?
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
end
