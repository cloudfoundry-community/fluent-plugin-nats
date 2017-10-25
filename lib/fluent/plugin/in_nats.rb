require "fluent/plugin/input"
require "nats/client"

module Fluent
  module Plugin
    class NATSInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("nats", self)

      helpers :thread

      config_param :host, :string, default: "localhost"
      config_param :user, :string, default: "nats"
      config_param :password, :string, default: "nats", secret: true
      config_param :port, :integer, default: 4222
      config_param :queues, :array, default: ["fluent.>"]
      config_param :tag, :string, default: "nats"
      config_param :ssl, :bool, default: false
      config_param :max_reconnect_attempts, :integer, default: 150
      config_param :reconnect_time_wait, :integer, default: 2

      def configure(conf)
        super

        @nats_config = {
          uri: "nats://#{@host}:#{@port}",
          ssl: @ssl,
          user: @user,
          pass: @password,
          reconnect_time_wait: @reconnect_time_wait,
          max_reconnect_attempts: @max_reconnect_attempts,
        }
      end

      def start
        super
        NATS.on_error do |error_message|
          log.error "Server Error: #{error_message}"
          exit!
        end
        run_reactor_thread
        thread_create(:nats_input_main, &method(:run))
        log.info "listening nats on #{@uri}/#{@queue}"
      end

      def shutdown
        @nats_conn.close
        EM.stop if EM.reactor_running?
        @reactor_thread.join if @reactor_thread
        super
      end

      def run
        EM.next_tick do
          @nats_conn = NATS.connect(@nats_config) do
            @queues.each do |queue|
              @nats_conn.subscribe(queue) do |msg, _reply, sub|
                tag = "#{@tag}.#{sub}"
                begin
                  message = JSON.parse(msg)
                rescue JSON::ParserError => e
                  log.error "Failed parsing JSON #{e.inspect}.  Passing as a normal string"
                  message = msg
                end
                time = Engine.now
                router.emit(tag, time, message || {})
              end
            end
          end
        end
      end

      private

      def run_reactor_thread
        return if EM.reactor_running?
        @reactor_thread = Thread.new do
          EM.run
        end
      end
    end
  end
end
