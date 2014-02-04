require 'thread'

class Alice
  include Vx::Consumer

  content_type 'text/plain'
  routing_key 'mykey'

  fanout

end

class Bob
  include Vx::Consumer

  exchange 'bob_exch',  durable: false, auto_delete: true
  queue    'bob_queue', exclusive: true, durable: false
  ack

  @@m         = Mutex.new
  @@collected = []

  class << self
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
    sleep 0.1
    ack
  end
end
