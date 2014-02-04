module Vx
  module Consumer
    module Instrument

      def instrument(name, payload, &block)
        name = "#{name}.consumer.vx"

        if Consumer.configuration.debug?
          $stdout.puts " --> #{name}: #{payload}"
        end

        if Consumer.configuration.instrumenter
          Consumer.configuration.instrumenter.instrument(name, payload, &block)
        else
          yield if block_given?
        end
      end

    end
  end
end
