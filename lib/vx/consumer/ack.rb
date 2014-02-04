module Vx
  module Consumer
    module Ack

      def ack(multiple = false)
        instrumentation = {
          consumer:      self.class.params.consumer_name,
          properties:    properties,
          multiple:      multiple,
        }
        if channel.open?
          channel.ack delivery_info.delivery_tag, multiple
          instrument("ack", instrumentation)
          true
        else
          instrument("ack_failed", instrumentation)
          false
        end
      end

      def nack(multiple = false, requeue = false)
        instrumentation = {
          consumer:      self.class.params.consumer_name,
          properties:    properties,
          multiple:      multiple,
          requeue:       requeue,
        }
        if channel.open?
          channel.ack delivery_info.delivery_tag, multiple, requeue
          instrument("nack", instrumentation)
          true
        else
          instrument("nack_failed", instrumentation)
          false
        end
      end

    end
  end
end
