require 'oj'

module Vx
  module Lib
    module Consumer
      class Serializer
        @@types = {}

        Type = Struct.new(:content_type) do
          def pack(&block)
            @pack = block if block_given?
            @pack
          end

          def unpack(&block)
            @unpack = block if block_given?
            @unpack
          end
        end

        class << self
          def types
            @@types
          end

          def define(content_type, &block)
            fmt = Type.new content_type
            fmt.instance_eval(&block)
            types.merge! content_type => fmt
          end

          def lookup(content_type)
            types[content_type]
          end

          def pack(content_type, body)
            if fmt = lookup(content_type)
              fmt.pack.call(body)
            else
              body
            end
          end

          def unpack(content_type, body, model)
            if fmt = lookup(content_type)
              fmt.unpack.call(body, model)
            end
          end
        end

        define 'text/plain' do
          pack do |body|
            body.to_s
          end

          unpack do |body, _|
            body
          end
        end

        define 'application/json' do
          pack do |body|
            encoded =
              if body.is_a?(String)
                body
              else
                ::Oj.dump(body, mode: :compat)
              end

            unless encoded.valid_encoding?
              encoded.encode!('UTF-8', invalid: :replace)
            end

            encoded
          end

          unpack do |payload, model|
            unless payload.valid_encoding?
              payload.encode!('UTF-8', invalid: :replace)
            end

            if model && model.respond_to?(:from_json)
              model.from_json payload
            else
              ::Oj.load(payload)
            end
          end
        end

        define 'application/x-protobuf' do

          pack do |object|
            object.encode.to_s
          end

          unpack do |payload, model|
            raise ModelIsNotDefined unless model
            model.decode payload
          end
        end

      end
    end
  end
end
