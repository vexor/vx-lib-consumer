require 'spec_helper'

describe Vx::Consumer do

  context "test consumer declaration" do
    context "alice" do
      subject { Alice.params }
      its(:exchange_name)    { should eq 'amq.topic' }
      its(:exchange_options) { should eq(durable: true, auto_delete: false) }
      its(:queue_name)       { should eq '' }
      its(:queue_options)    { should eq(exclusive: false, durable: true, auto_delete: false) }
      its(:ack)              { should be_true }
      its(:routing_key)      { should eq 'mykey' }
      its(:headers)          { should be_nil }
      its(:content_type)     { should eq 'text/plain' }
    end

    context "bob" do
      subject { Bob.params }
      its(:exchange_name)    { should eq 'bob_exch' }
      its(:exchange_options) { should eq(durable: false, auto_delete: true) }
      its(:queue_name)       { should eq 'bob_queue' }
      its(:queue_options)    { should eq(exclusive: true) }
      its(:ack)              { should be_false }
      its(:routing_key)      { should be_nil }
      its(:headers)          { should eq(key: "me") }
      its(:content_type)     { should eq 'application/json' }
    end
  end

end
