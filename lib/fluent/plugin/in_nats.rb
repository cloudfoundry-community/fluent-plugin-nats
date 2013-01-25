module Fluent
  class NATSInput < Input
    Fluent::Plugin.register_input("nats", self)

    config_param :host, :string, :default => "localhost"
    config_param :user, :string, :default => "nats"
    config_param :password, :string, :default => "nats"
    config_param :port, :integer, :default => 4222
    config_param :queue, :string, :default => "fluent.>"
    config_param :tag, :string, :default => "nats"

    def initialize
      require "nats/client"

      NATS.on_error { |err| puts "Server Error: #{err}"; exit! }
      super
    end

    def configure(conf)
      super
      @conf = conf
      @uri = "nats://#{@user}:#{@password}@#{@host}:#{@port}"
      unless @host && @queue
        raise ConfigError, "'host' and 'queue' must be all specified."
      end
    end

    def start
      super
      run_reactor_thread
      @thread = Thread.new(&method(:run))
      $log.info "listening nats on #{@uri}/#{@queue}"
    end

    def shutdown
      super
      @nats_conn.close
      @thread.join
      EM.stop if EM.reactor_running?
      @reactor_thread.join if @reactor_thread
    end

    def run
      EM.next_tick {
        @nats_conn = NATS.connect(:uri => @uri) {
          @nats_conn.subscribe(@queue) do |msg, reply, sub|
            tag = "#{@tag}.#{sub}"
            msg_json = JSON.parse(msg)
            time = msg_json["fluent_timestamp"] || Time.now.to_i 
            Engine.emit(tag, time, msg_json)
          end
        }
      }
    end

    private
    def run_reactor_thread
      unless EM.reactor_running?
        @reactor_thread = Thread.new { EM.run }
      end
    end

  end
end
