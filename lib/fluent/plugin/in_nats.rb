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

      #["TERM", "INT"].each { |sig| trap(sig) { NATS.stop } }
      NATS.on_error { |err| puts "Server Error: #{err}"; exit! }
      super
    end

    def configure(conf)
      super
      @conf = conf
      unless @host && @queue
        raise ConfigError, "'host' and 'queue' must be all specified."
      end
    end

    def start
      super
      $log.info "listening nats on nats://#{host}:#{port}/#{queue}"
      @thread = Thread.new(&method(:run))
    end

    def shutdown
      super
      NATS.stop
      @thread.join
    end

    def run
      NATS.start {
        NATS.subscribe(@queue) do |msg, reply, sub|
          Engine.emit(sub, 0, msg)
        end
      }
    end
  end
end
