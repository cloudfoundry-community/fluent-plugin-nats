#!/usr/bin/env ruby

require "bundler/setup"
require "nats/client"
require "optparse"
require "uri"

def main(argv)
  uri = nil
  queue = nil
  message = nil
  parser = OptionParser.new
  parser.on("--uri=URI", "NATS server URI") do |value|
    uri = URI.parse(value)
  end
  parser.on("--queue=QUEUE", "Queue names") do |value|
    queue = value
  end
  parser.on("--message=MESSAGE", "Message JSON") do |value|
    message = value[1..-2]
  end
  begin
    parser.parse!
  rescue OptionParser::ParseError => ex
    puts ex.message
  end
  options = {
    uri: uri.to_s
  }
  options[:user] = uri.user if uri.user
  options[:pass] = uri.password if uri.password
  NATS.start(options) do
    NATS.publish(queue, message) do
      sleep 0.5
      NATS.stop
    end
  end
end

main(ARGV)
