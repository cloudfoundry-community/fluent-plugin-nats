require 'test/unit'
require 'fluent/test'
require 'lib/fluent/plugin/in_nats.rb'
require 'nats/client'
require 'test_helper'

class NATSInputTest < Test::Unit::TestCase
  include NATSTestHelper

  CONFIG = %[
    port 4222
    host localhost
    user nats
    password nats
  ]

  def basic_queue_conf
    CONFIG + %[
      queue fluent.>
    ]
  end

  def multiple_queue_conf
    CONFIG + %[
      queue fluent.>, fluent2.>
    ]
  end

  def ssl_conf
    basic_queue_conf + %[
      ssl true
    ]
  end

  def create_driver(conf)
    Fluent::Test::InputTestDriver.new(Fluent::NATSInput).configure(conf)
  end

  sub_test_case "configure" do
    def test_configure_basic
      d = create_driver basic_queue_conf
      assert_equal 4222, d.instance.port
      assert_equal 'localhost', d.instance.host
      assert_equal 'nats', d.instance.user
      assert_equal 'nats', d.instance.password
      assert_equal 'fluent.>', d.instance.queue
    end

    def test_configure_multiple_queue
      d = create_driver multiple_queue_conf
      assert_equal 4222, d.instance.port
      assert_equal 'localhost', d.instance.host
      assert_equal 'nats', d.instance.user
      assert_equal 'nats', d.instance.password
      assert_equal 'fluent.>, fluent2.>', d.instance.queue
    end

    def test_configure_basic_with_ssl
      d = create_driver ssl_conf
      assert_equal 4222, d.instance.port
      assert_equal 'localhost', d.instance.host
      assert_equal 'nats', d.instance.user
      assert_equal 'nats', d.instance.password
      assert_equal 'fluent.>', d.instance.queue
      assert_equal true, d.instance.ssl
    end
  end

  sub_test_case "events" do
    def test_emit_with_credentials
      d = create_driver basic_queue_conf

      time = Time.parse("2011-01-02 13:14:15 UTC").to_i
      Fluent::Engine.now = time

      d.expect_emit "nats.fluent.test1", time, {"message"=>'nats', "fluent_timestamp"=>time}
      d.expect_emit "nats.fluent.test2", time, {"message"=>'nats', "fluent_timestamp"=>time}

      uri = "nats://#{d.instance.user}:#{d.instance.password}@#{d.instance.host}:#{d.instance.port}"

      start_nats(uri)
      d.run do
        d.expected_emits.each { |tag, time, record|
          send(uri, tag[5..-1], record)
          sleep 0.5
        }
      end
      kill_nats
    end

    def test_emit_without_credentials
      d = create_driver basic_queue_conf

      time = Time.parse("2011-01-02 13:14:15 UTC").to_i
      Fluent::Engine.now = time

      d.expect_emit "nats.fluent.test1", time, {"message"=>'nats', "fluent_timestamp"=>time}
      d.expect_emit "nats.fluent.test2", time, {"message"=>'nats', "fluent_timestamp"=>time}

      uri = "nats://#{d.instance.host}:#{d.instance.port}"

      start_nats(uri)
      d.run do
        d.expected_emits.each { |tag, time, record|
          send(uri, tag[5..-1], record)
          sleep 0.5
        }
      end
      kill_nats
    end

    def test_emit_multiple_queues
      d = create_driver multiple_queue_conf

      time = Time.parse("2011-01-02 13:14:15 UTC").to_i
      Fluent::Engine.now = time

      d.expect_emit "nats.fluent.test1", time, {"message"=>'nats', "fluent_timestamp"=>time}
      d.expect_emit "nats.fluent.test2", time, {"message"=>'nats', "fluent_timestamp"=>time}
      d.expect_emit "nats.fluent2.test1", time, {"message"=>'nats', "fluent_timestamp"=>time}
      d.expect_emit "nats.fluent2.test2", time, {"message"=>'nats', "fluent_timestamp"=>time}

      uri = "nats://#{d.instance.host}:#{d.instance.port}"

      start_nats(uri)
      d.run do
        d.expected_emits.each { |tag, time, record|
          send(uri, tag[5..-1], record)
          sleep 0.5
        }
      end
      kill_nats
    end

    def test_emit_without_fluent_timestamp
      d = create_driver basic_queue_conf

      time = Time.now.to_i
      Fluent::Engine.now = time

      d.expect_emit "nats.fluent.test1", time, {"message"=>'nats'}

      uri = "nats://#{d.instance.host}:#{d.instance.port}"
      start_nats(uri)
      d.run do
        d.expected_emits.each do |tag, time, record|
          send(uri, tag[5..-1], record)
          sleep 0.5
        end
      end
      kill_nats
    end

    def test_emit_arrays
      d = create_driver basic_queue_conf

      time = Time.now.to_i
      Fluent::Engine.now = time
      
      d.expect_emit "nats.fluent.empty_array", time, []
      d.expect_emit "nats.fluent.string_array", time, %w(one two three)

      uri = "nats://#{d.instance.host}:#{d.instance.port}"
      start_nats(uri)
      d.run do
        d.expected_emits.each do |tag, time, record|
          send(uri, tag[5..-1], record)
          sleep 0.5
        end
      end
      kill_nats
    end

    def test_empty_publish_string
      d = create_driver basic_queue_conf

      time = Time.now.to_i
      Fluent::Engine.now = time

      d.expect_emit "nats.fluent.nil", time, nil

      uri = "nats://#{d.instance.host}:#{d.instance.port}"
      start_nats(uri)
      d.run do
        d.expected_emits.each do |tag, time, record|
          send(uri, tag[5..-1], nil)
          sleep 0.5
        end
      end
      kill_nats
    end

    def test_regular_publish_string
      d = create_driver basic_queue_conf

      time = Time.now.to_i
      Fluent::Engine.now = time

      d.expect_emit "nats.fluent.string", time, "Lorem ipsum dolor sit amet"

      uri = "nats://#{d.instance.host}:#{d.instance.port}"
      start_nats(uri)
      d.run do
        d.expected_emits.each do |tag, time, record|
          send(uri, tag[5..-1], "Lorem ipsum dolor sit amet")
          sleep 0.5
        end
      end
      kill_nats
    end
  end

  def setup
    Fluent::Test.setup
  end

  def send(uri, tag, msg)
    EM.run {
      n = NATS.connect(:uri => uri) 
      n.publish(tag,msg.to_json) 
      n.close
    }
  end
end
