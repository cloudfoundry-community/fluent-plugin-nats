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

  def test_emit
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    Fluent::Engine.now = time

    d.expect_emit "fluent.test1", 0, {"message"=>'nats'}.to_json
    d.expect_emit "fluent.test2", 0, {"message"=>'nats'}.to_json

    start_nats
    d.run do
      d.expected_emits.each { |tag, time, record|
        send(tag, record)
        sleep 0.5
      }
    end
    kill_nats
  end

  def setup
    Fluent::Test.setup
  end

  def send(tag, msg)
    EM.run {
      n = NATS.connect 
      n.publish(tag,msg) 
      n.close
    }
  end
end
