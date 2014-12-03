require 'timeout'
require 'spec_helper'

describe Vx::Lib::Consumer, '(rpc)' do

  it "simple rep/rep" do
    sleep 1
    consumer = Kenny.subscribe
    sleep 1

    re = Kenny.rpc.call(:kill, ['Oh'], timeout: 60)
    expect(re).to eq 'rep: Oh'

    Timeout.timeout(3) do
      consumer.graceful_shutdown
    end

    Kenny.rpc.client.cancel
    sleep 1
  end

  it "rep/rep in multithreaded environment" do
    re  = []
    handle_errors do
      cns = []
      ths = []

      30.times do |n|
        cns << Kenny.subscribe
      end

      idx = 0
      10.times do |i|
        100.times do |j|
          idx += 1
          n = "%08d" % idx
          ths << Thread.new do
            re << Kenny.rpc.call(:kill, [n])
          end
        end
        sleep 0.1
      end

      Timeout.timeout(10) do
        ths.map(&:join)
      end

      Timeout.timeout(10) do
        cns.map(&:graceful_shutdown)
      end

      Kenny.rpc.client.cancel
      sleep 1
    end

    expect(re.size).to eq 10 * 100
  end

  def handle_errors
    begin
      yield
    rescue Exception => e
      Vx::Lib::Consumer.exception_handler(e, {})
      raise e
    end
  end
end
