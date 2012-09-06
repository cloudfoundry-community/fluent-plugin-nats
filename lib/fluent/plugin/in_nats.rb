module Fluent
  class NATSInput < Input
    Fluent::Plugin.register_input("nats", self)

    config_param :host, :string, :default => "localhost"
    config_param :user, :string, :default => "nats"
    config_param :password, :string, :default => "nats"
    config_param :port, :integer, :default => 4222
    config_param :queue, :string, :default => "fluent.>"

    def initialize
      require "nats/client"

      NATS.on_error { |err| puts "Server Error: #{err}"; exit! }
      super
    end

    def configure(conf)
      super
      @conf = conf
      @uri = "nats://#{user}:#{password}@#{host}:#{port}"
      unless @host && @queue
        raise ConfigError, "'host' and 'queue' must be all specified."
      end
    end

    def start
      super
      $log.info "listening nats on #{@uri}/#{@queue}"
      @main_thread = Thread.current
      @thread = Thread.new(&method(:run))
      Thread.stop
      @thread
    end

    def shutdown
      super
      NATS.stop
      @thread.join
    end

    def run
      if EM.reactor_running?
        $log.info "Reactor already running"
        NATS.connect(:uri => @uri) {
          NATS.subscribe(@queue) do |msg, reply, sub|
            tag = "#{@tag}.#{sub}"
            msg_json = JSON.parse(msg)
            time = msg_json["fluent_timestamp"] || Time.now.to_i 
            Engine.emit(tag, time, msg_json)
          end
          @main_thread.wakeup
        }
      else 
        $log.info "Reactor not running. Starting..."
        NATS.start(:uri => @uri) {
          NATS.subscribe(@queue) do |msg, reply, sub|
            tag = "#{@tag}.#{sub}"
            msg_json = JSON.parse(msg)
            time = msg_json["fluent_timestamp"] || Time.now.to_i 
            Engine.emit(sub, time, msg_json)
          end
          $log.info "Reactor running #{EM.reactor_running?}"
          @main_thread.wakeup
        }
      end
    end
  end
end
