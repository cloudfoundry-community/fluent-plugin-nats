require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'fluent/test'
unless ENV.has_key?('VERBOSE')
  nulllogger = Object.new
  nulllogger.instance_eval {|obj|
    def method_missing(method, *args)
      # pass
    end
  }
  $log = nulllogger
end

class Test::Unit::TestCase
end

require 'nats/client'

module NATSTestHelper
  def run_server(uri)
    uri = URI.parse(uri)
    unless NATS.server_running?(uri)
      args = prepare_args(uri)
      # We can invoke gnatsd before run test
      pid = spawn("gnatsd", *args, out: "/dev/null", err: "/dev/null")
      NATS.wait_for_server(uri, 10)
    end
    yield
  rescue => ex
    if ex.is_a?(Test::Unit::AssertionFailedError)
      raise ex
    else
      puts "#{ex.class}: #{ex.message}"
      puts ex.backtrace
    end
  ensure
    Process.kill(:INT, pid) if pid
  end

  def prepare_args(uri)
    args = ["-p", uri.port.to_s]
    args.push("--user", uri.user) if uri.user
    args.push("--pass", uri.password) if uri.password
    args.push("--trace", "-D")
    args.push(*@flags) if @flags
    args
  end
end
