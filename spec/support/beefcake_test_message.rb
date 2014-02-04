require 'beefcake'

class BeefcakeTestMessage
  include Beefcake::Message

  required :x, :int32, 1
  required :y, :int32, 2
end
