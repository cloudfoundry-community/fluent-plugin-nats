require "test_helper"
require "fluent/test/driver/output"
require "fluent/test/driver/input"
require "fluent/plugin/out_nats"
require "fluent/plugin/in_nats"
require "fluent/time"

class NATSOutputTest < Test::Unit::TestCase
  include NATSTestHelper

  CONFIG = %[
    port 4222
    host localhost
    user nats
    password nats
  ]

  CONFIG_INPUT = CONFIG + %[
    queues test.>
    tag nats
  ]

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::NATSOutput).configure(conf)
  end

  def create_input_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::NATSInput).configure(conf)
  end

  def setup
    Fluent::Test.setup
    @time = Time.parse("2011-01-02 13:14:15 UTC")
    Timecop.freeze(@time)
  end

  def teardown
    Timecop.return
  end

  test "configuration test" do
    d = create_driver(CONFIG)
    assert_equal 4222, d.instance.port
    assert_equal "localhost", d.instance.host
    assert_equal "nats", d.instance.user
    assert_equal "nats", d.instance.password
  end

  test "publish an event to NATS" do
    d = create_driver(CONFIG)
    input_driver = create_input_driver(CONFIG_INPUT)

    time = Fluent::EventTime.now

    uri = generate_uri(d)

    run_server(uri) do
      input_driver.run(expect_records: 1) do
        d.run(default_tag: 'test.log') do
          d.feed(time, {"test" => "test1"})
        end
      end
    end
    event = input_driver.events[0]
    assert_equal(event[0], 'nats.test.log')
    assert_equal(event[2], {"test" => "test1"})
  end

  def generate_uri(driver)
    user = driver.instance.user
    pass = driver.instance.password
    host = driver.instance.host
    port = driver.instance.port
    if user && pass
      "nats://#{user}:#{pass}@#{host}:#{port}"
    else
      "nats://#{host}:#{port}"
    end
  end
end
