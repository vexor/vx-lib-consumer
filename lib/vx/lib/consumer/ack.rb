module Vx
  module Lib
    module Consumer
      module Ack

        def ack(multiple = false)
          if _channel.open?
            _channel.ack delivery_info.delivery_tag, multiple
            true
          else
            false
          end
        end

        def nack(multiple = false, requeue = false)
          if _channel.open?
            _channel.ack delivery_info.delivery_tag, multiple, requeue
            true
          else
            false
          end
        end

      end
    end
  end
end
