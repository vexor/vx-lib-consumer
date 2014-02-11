%w{
  version
  error
  configuration
  instrument
  session
  params
  serializer
  subscriber
  publish
  subscribe
  ack
}.each do |f|
  require File.expand_path("../consumer/#{f}", __FILE__)
end

module Vx
  module Consumer

    attr_accessor :properties
    attr_accessor :delivery_info
    attr_accessor :_channel

    def self.included(base)
      base.extend ClassMethods
      base.extend Instrument
      base.extend Publish
      base.extend Subscribe
      base.send :include, Ack
      base.send :include, Instrument
    end

    module ClassMethods
      def params
        @params ||= Params.new(self.name)
      end

      def exchange(*args)
        params.exchange_options = args.last.is_a?(Hash) ? args.pop : nil
        params.exchange_name    = args.first
      end

      def fanout
        params.exchange_type = :fanout
      end

      def topic
        params.exchange_type = :topic
      end

      def queue(*args)
        params.queue_options = args.last.is_a?(Hash) ? args.pop : nil
        params.queue_name    = args.first
      end

      def routing_key(name)
        params.routing_key = name
      end

      def headers(value)
        params.headers = value
      end

      def content_type(value)
        params.content_type = value
      end

      def ack
        params.ack = true
      end

      def model(value)
        params.model = value
      end

      def session
        Consumer.session
      end

      def configuration
        Consumer.configuration
      end

      def with_middlewares(name, env, &block)
        Consumer.configuration.builders[name].to_app(block).call(env)
      end
    end

    extend self

    @@session       = Session.new
    @@configuration = Configuration.new

    def shutdown
      session.shutdown
    end

    def live?
      session.live?
    end

    def wait_shutdown(timeout = nil)
      session.wait_shutdown(timeout)
    end

    def configure
      yield configuration
    end

    def configuration
      @@configuration
    end

    def session
      @@session
    end

    def exception_handler(e, env)
      unless env.is_a?(Hash)
        env = {env: env}
      end
      configuration.on_error.call(e, env)
    end

  end
end
