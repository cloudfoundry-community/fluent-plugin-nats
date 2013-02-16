require 'test/unit'
require 'fluent/test'
require 'lib/fluent/plugin/in_nats'
require 'nats/client'
require 'test_helper'

class NATSInputTest < Test::Unit::TestCase
  include NATSTestHelper

  CONFIG = %[
    port 4222
    host localhost
    user nats
    password nats
    queue fluent.>
  ]

  
  def create_driver(conf=CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::NATSInput).configure(conf)
  end
  
  def test_configure
    d = create_driver
    assert_equal 4222, d.instance.port
    assert_equal 'localhost', d.instance.host
    assert_equal 'nats', d.instance.user
    assert_equal 'nats', d.instance.password
    assert_equal 'fluent.>', d.instance.queue
  end

  def test_emit_with_credentials
    d = create_driver

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
    d = create_driver

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

  def test_emit_without_fluent_timestamp
    d = create_driver

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
    d = create_driver

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
    d = create_driver

    time = Time.now.to_i
    Fluent::Engine.now = time

    d.expect_emit "nats.fluent.nil", time, nil

    uri = "nats://#{d.instance.host}:#{d.instance.port}"
    start_nats(uri)
    d.run do
      d.expected_emits.each do |tag, time, record|
        EM.run do
          n = NATS.connect uri: uri
          n.publish tag[5..-1]
          n.close
        end
        sleep 0.5
      end
    end
    kill_nats
  end

  def test_regular_publish_string
    d = create_driver

    time = Time.now.to_i
    Fluent::Engine.now = time

    d.expect_emit "nats.fluent.string", time, "Lorem ipsum dolor sit amet"

    uri = "nats://#{d.instance.host}:#{d.instance.port}"
    start_nats(uri)
    d.run do
      d.expected_emits.each do |tag, time, record|
        EM.run do
          n = NATS.connect uri: uri
          n.publish tag[5..-1], "Lorem ipsum dolor sit amet"
          n.close
        end
        sleep 0.5
      end
    end
    kill_nats
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
