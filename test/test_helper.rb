require "bundler/setup"
require "test/unit"

$LOAD_PATH.unshift(File.join(__dir__, "..", "lib"))
$LOAD_PATH.unshift(__dir__)
require "fluent/test"
require "nats/client"

module NATSTestHelper
  def run_server(uri)
    uri = URI.parse(uri)
    unless NATS.server_running?(uri)
      args = prepare_args(uri)
      # We can invoke gnatsd before run test
      pid = spawn("gnatsd", *args, out: "/dev/null", err: "/dev/null")
      NATS.wait_for_server(uri, 10)
    end
    yield
  rescue
    raise
  ensure
    Process.kill(:INT, pid) if pid
  end

  def prepare_args(uri)
    args = ["-p", uri.port.to_s]
    args.push("--user", uri.user) if uri.user
    args.push("--pass", uri.password) if uri.password
    args.push(*@flags) if @flags
    args
  end
end
