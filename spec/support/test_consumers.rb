require 'thread'

class Alice
  include Vx::Lib::Consumer

  content_type 'text/plain'
  routing_key 'mykey'
  fanout

end

class Bob
  include Vx::Lib::Consumer

  exchange 'bob_exch',  durable: false, auto_delete: true
  queue    'bob_queue', durable: false, auto_delete: true
  ack

  @@m         = Mutex.new
  @@collected = []

  class << self

    attr_accessor :timeout

    def _collected
      @@collected
    end

    def _reset
      @@m.synchronize do
        @@collected = []
      end
    end

    def _save(payload)
      @@m.synchronize do
        @@collected << payload
      end
    end
  end

  def perform(payload)
    self.class._save payload
    sleep self.class.timeout
    ack
  end
end
