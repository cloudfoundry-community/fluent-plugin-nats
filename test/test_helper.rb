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

  def server_pid
    @pid ||= File.read(@pid_file).chomp.to_i
  end 

  def setup_nats_server
    @uri = URI.parse('nats://localhost:4222')
    @pid_file = '/tmp/test-nats.pid'
    args = "-p #{@uri.port} -P #{@pid_file}"
    args += " --user #{@uri.user}" if @uri.user
    args += " --pass #{@uri.password}" if @uri.password
    args += " #{@flags}" if @flags
    args += ' -d'
  end

  def kill_nats
    if File.exists? @pid_file
      %x[kill -9 #{server_pid} 2> /dev/null]
      %x[rm #{@pid_file} 2> /dev/null]
      %x[rm #{NATS::AUTOSTART_LOG_FILE} 2> /dev/null]
      @pid = nil
    end
  end
  
  def start_nats

    if NATS.server_running? @uri
      @was_running = true
      return 0
    end

    %x[bundle exec nats-server #{setup_nats_server} 2> /dev/null]
    exitstatus = $?.exitstatus
    NATS.wait_for_server(@uri, 10)
    exitstatus
  end
end


