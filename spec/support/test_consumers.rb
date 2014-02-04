class Alice
  include Vx::Consumer

  content_type 'text/plain'
  routing_key 'mykey'
  ack true

end

class Bob
  include Vx::Consumer

  exchange 'bob_exch',  durable: false, auto_delete: true
  queue    'bob_queue', exclusive: true

  headers key: "me"
end
