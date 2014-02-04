module Vx
  module Consumer
    Params = Struct.new(:consumer_class) do

      attr_accessor :exchange_name, :exchange_options
      attr_accessor :queue_name, :queue_options
      attr_accessor :routing_key, :headers
      attr_accessor :content_type
      attr_accessor :ack
      attr_accessor :exchange_type
      attr_accessor :model

      def exchange_name
        @exchange_name || default_exchange_name
      end

      def queue_name
        @queue_name || ""
      end

      def ack
        !!@ack
      end

      def content_type
        @content_type || config.content_type
      end

      def exchange_type
        @exchange_type || config.default_exchange_type
      end

      def exchange_options
        (@exchange_options || config.default_exchange_options).merge(type: exchange_type)
      end

      def queue_options
        @queue_options || config.default_queue_options
      end

      def publish_options
        config.default_publish_options
      end

      def bind_options
        opts = { }
        opts.merge!(routing_key: routing_key) if routing_key
        opts.merge!(headers: headers) if headers
        opts
      end

      def consumer_name
        consumer_class.to_s
      end

      private

        def config
          Consumer.configuration
        end

        def default_exchange_name
          "amq.#{exchange_type}"
        end

    end
  end
end
