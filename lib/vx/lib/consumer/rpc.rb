require 'json'
require 'thread'
require 'securerandom'

module Vx
  module Lib
    module Consumer
      module Rpc

        RPC_EXCHANGE_NAME  = "".freeze
        JSON_CONTENT_TYPE  = 'application/json'.freeze
        RPC_PAYLOAD_METHOD = 'method'.freeze
        RPC_PAYLOAD_PARAMS = 'params'.freeze
        RPC_PAYLOAD_RESULT = 'result'.freeze

        class RpcProxy

          attr_reader :client

          def initialize(consumer)
            @parent   = consumer
            @client   = RpcClient.new consumer
            @methods  = {}
            @defined  = false
          end

          def call(method, args, options = {})
            ns = @parent.params.consumer_id
            @client.call ns, method, args, options
          end

          def define
            @parent.exchange RPC_EXCHANGE_NAME
            @parent.queue    "vx.rpc.#{@parent.params.consumer_id}".freeze, durable: false, auto_delete: true

            @parent.send :define_method, :perform do |payload|
              self.class.rpc.process_payload(properties, payload)
            end

            @defined = true
          end

          def action(name, fn)
            define unless @defined
            @methods[name.to_s] = fn
          end

          def process_payload(properties, payload)
            m = payload[RPC_PAYLOAD_METHOD]
            p = payload[RPC_PAYLOAD_PARAMS]

            if fn = @methods[m]
              re = fn.call(*p)
              @parent.publish(
                { 'result' => re },
                routing_key:    properties[:reply_to],
                correlation_id: properties[:correlation_id],
                content_type:   JSON_CONTENT_TYPE
              )
            end
          end
        end

        class RpcClient

          REP    = "rep".freeze
          REQ    = "req".freeze

          attr_reader :consumer

          def initialize(consumer)
            @consumer = consumer
            @consumed = false
            @await    = {}
            @mutex    = Mutex.new
            @wakeup   = Mutex.new
          end

          def consume
            return if @consumed

            ch = consumer.session.conn.create_channel
            consumer.session.assign_error_handlers_to_channel(ch)

            @q = ch.queue(RPC_EXCHANGE_NAME, exclusive: true)

            @subscriber =
              @q.subscribe do |delivery_info, properties, payload|
                handle_delivery ch, properties, payload
              end
            @consumed = true
          end

          def handle_delivery(ch, properties, payload)

            if payload
              payload = ::JSON.parse(payload)
            end

            env = {
              consumer:   consumer.params.consumer_name,
              queue:      @q.name,
              rpc:        REP,
              channel:    ch.id,
              payload:    payload,
              properties: properties
            }

            consumer.with_middlewares :sub, env do
              call_id = properties[:correlation_id]
              c = @mutex.synchronize{ @await.delete(call_id) }
              if c
                @mutex.synchronize do
                  @await[call_id] = [properties, payload]
                end
                @wakeup.synchronize do
                  c.signal
                end
              end
            end
          end

          def call(ns, method, params, options = {})
            timeout     = options[:timeout] || 3
            routing_key = options[:routing_key] || "vx.rpc.#{ns}".freeze
            call_id     = SecureRandom.uuid
            cond        = ConditionVariable.new
            result      = nil

            message = {
              method: method.to_s,
              params: params,
              id:     call_id
            }

            with_queue do |q|

              consumer.session.with_pub_channel do |ch|
                exch = ch.exchange RPC_EXCHANGE_NAME

                env = {
                  payload:     message,
                  rpc:         REQ,
                  exchange:    exch.name,
                  consumer:    consumer.params.consumer_name,
                  properties:  { routing_key: routing_key, correlation_id: call_id },
                  channel:     ch.id
                }

                @mutex.synchronize { @await[call_id] = cond }

                consumer.with_middlewares :pub, env do
                  exch.publish(
                    message.to_json,
                    routing_key:    routing_key,
                    correlation_id: call_id,
                    reply_to:       q.name,
                    content_type:   JSON_CONTENT_TYPE
                  )
                end

                @wakeup.synchronize{
                  cond.wait(@wakeup, timeout)
                }
                @mutex.synchronize do
                  _, payload = @await.delete(call_id)
                  if payload
                    result = payload[RPC_PAYLOAD_RESULT]
                  else
                    nil
                  end
                end
              end
            end

            result

          end

          def with_queue
            consume
            yield @q
          end

          def subscriber?
            !!@subscriber
          end

          def cancel
            if subscriber?
              @subscriber.cancel
              @subscriber = nil
              @consumed   = false
            end
          end
        end

        def rpc
          @rpc ||= RpcProxy.new(self)
        end

      end
    end
  end
end
