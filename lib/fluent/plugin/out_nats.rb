require "fluent/plugin/output"
require "nats/client"

module Fluent
  module Plugin
    class NATSOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output('nats', self)

      helpers :formatter, :thread, :inject

      DEFAULT_FORMAT_TYPE = 'json'

      desc "NATS server hostname"
      config_param :host, :string, default: "localhost"
      desc "NATS server port"
      config_param :port, :integer, default: 4222
      desc "Username for authorized connection"
      config_param :user, :string, default: "nats"
      desc "Password for authorized connection"
      config_param :password, :string, default: "nats", secret: true
      desc "Enable secure SSL/TLS connection"
      config_param :ssl, :bool, default: false
      desc "The max number of reconnect tries"
      config_param :max_reconnect_attempts, :integer, default: 150
      desc "The number of seconds to wait between reconnect tries"
      config_param :reconnect_time_wait, :integer, default: 2

      config_section :format do
        config_set_default :@type, DEFAULT_FORMAT_TYPE
        config_set_default :add_newline, false
      end

      def multi_workers_ready?
        true
      end

      attr_accessor :formatter

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
        @formatter = formatter_create
      end

      def start
        super
        thread_create(:nats_output_main, &method(:run))
      end

      def shutdown
        EM.next_tick do
          NATS.stop
        end
        super
      end

      def run
        NATS.on_error do |error|
          log.error "Server Error:", error: error
          # supervisor will restart worker
          exit!
        end
        NATS.start(@nats_config) do
          log.info "nats client is running for #{@nats_config[:uri]}"
        end
      end

      def process(tag, es)
        es = inject_values_to_event_stream(tag, es)
        es.each do |time,record|
          EM.next_tick do
            NATS.publish(tag, format(tag, time, record))
          end
        end
      end

      def format(tag, time, record)
        @formatter.format(tag, time, record)
      end
    end
  end
end
