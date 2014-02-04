%w{
  version
  error
  configuration
  instrument
  session
  params
  publish
}.each do |f|
  require File.expand_path("../consumer/#{f}", __FILE__)
end

module Vx
  module Consumer

    def self.included(base)
      base.extend ClassMethods
      base.extend Publish
      base.extend Instrument
    end

    module ClassMethods
      def params
        @params ||= Params.new(self.name)
      end

      def exchange(*args)
        params.exchange_options = args.last.is_a?(Hash) ? args.pop : {}
        params.exchange_name    = args.first
      end

      def type(exch_type)
        params.exchange_type = exch_type
      end

      def queue(*args)
        params.queue_options = args.last.is_a?(Hash) ? args.pop : {}
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

      def ack(value)
        params.ack = value
      end

      def session
        Consumer.session
      end
    end

    extend self

    @@session       = Session.new
    @@configuration = Configuration.new

    def shutdown
      session.shutdown
    end

    def shutdown?
      session.shutdown?
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

  end
end
