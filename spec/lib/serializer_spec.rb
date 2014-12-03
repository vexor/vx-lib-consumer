require 'json'
require 'beefcake'
require 'spec_helper'

describe Vx::Lib::Consumer::Serializer do
  let(:s) { described_class }

  context "text/plain" do
    let(:payload) { 'payload' }

    it "should pack payload" do
      expect(s.pack('text/plain', payload)).to eq 'payload'
    end

    it "should unpack payload" do
      expect(s.unpack('text/plain', payload, nil)).to eq 'payload'
    end
  end

  context "application/json" do
    let(:payload) { {a: 1} }

    it "should pack payload" do
      expect(s.pack('application/json', payload)).to eq "{\"a\":1}"
    end

    it "should unpack payload" do
      expect(s.unpack('application/json', payload.to_json, nil)).to eq("a"=>1)
    end
  end

  context "application/x-protobuf" do
    let(:payload) { BeefcakeTestMessage.new(x: 1, y: 2) }

    it "should pack payload" do
      expect(s.pack('application/x-protobuf', payload)).to eq payload.encode.to_s
    end

    it "should unpack payload" do
      expect(s.unpack('application/x-protobuf', payload.encode.to_s, BeefcakeTestMessage)).to eq payload
    end
  end
end
