module Vx
  module Lib
    module Consumer
      module Instrument

        def instrument(name, payload, &block)
          name = "#{name}.consumer.vx".freeze

          if Consumer.configuration.debug?
            $stdout.puts " --> #{name}: #{payload}"
          end

          if Consumer.configuration.instrumenter
            Consumer.configuration.instrumenter.instrument(name, payload, &block)
          else
            begin
              yield if block_given?
            rescue Exception => e
              Consumer.handle_exception(e, {})
            end
          end
        end

      end
    end
  end
end
