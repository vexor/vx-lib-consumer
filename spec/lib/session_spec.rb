require 'spec_helper'

describe Vx::Consumer::Session do
  let(:sess) { described_class.new }
  subject { sess }

  after do
    sess.close
  end

  it { should be }

  it "should successfuly open connection" do
    expect {
      sess.open
    }.to change(sess, :open?).to(true)
  end

  it "should successfuly open connection in multithread environment" do
    (0..10).map do |n|
      Thread.new do
        sess.open
      end
    end.map(&:value)

    expect(sess).to be_open
  end

  it "should declare exchange using default options" do
    sess.open

    ret = []
    sess.with_channel do |ch|
      x = sess.declare_exchange ch, 'vexor'
      begin
        ret << x.name
        ret << x.durable?
        ret << x.auto_delete?
      ensure
        x.delete
      end
    end
    expect(ret).to eq ['vexor', true, false]
  end

  it "should declare queue using default options" do
    sess.open

    ret = []
    sess.with_channel do |ch|
      q = sess.declare_queue ch, 'vexor'
      begin
        ret << q.name
        ret << q.durable?
        ret << q.auto_delete?
        ret << q.exclusive?
      ensure
        q.delete
      end
    end
    expect(ret).to eq ['vexor', true, false, false]
  end

end
