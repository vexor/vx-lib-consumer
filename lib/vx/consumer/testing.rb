require File.expand_path("../../consumer", __FILE__)

module Vx
  module Consumer

    module Testing

      extend self

      @@messages = Hash.new { |h,k| h[k] = [] }
      @@messages_and_options = Hash.new { |h,k| h[k] = [] }

      def messages
        @@messages
      end

      def messages_and_options
        @@messages_and_options
      end

      def clear
        messages.clear
        messages_and_options.clear
      end
    end

    module Consumer::Publish

      def publish(message, options = nil)
        options ||= {}
        Testing.messages[params.exchange_name] << message
        Testing.messages_and_options[params.exchange_name] << [message, options]
        self
      end

      def messages
        Testing.messages[params.exchange_name]
      end

      def messages_and_options
        Testing.messages_and_options[params.exchange_name]
      end

    end

  end
end
