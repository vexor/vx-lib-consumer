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

end
