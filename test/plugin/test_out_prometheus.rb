require "helper"
require "fluent/plugin/out_prometheus.rb"

class PrometheusOutTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  CONFIG = %[
    gateway localhost:9091
    job impala-kudu-metrics
  ]

  messages = [
    { "message" => "Unable to open scanner for node with id ‘0’ for Kudu table ‘nc.d_so’ : Time out : exceeded configure scan timeout of 180.000s: Scan RPC to x.x.x.x:7050 timed out after 179.999 (ON_OUTBOUND_QUEUE)", "category" => "prometheus", "type" => "SCAN_TIMEOUT", "metric-type" => "Counter", "metric-name" => "kudu_scan_timeout_count", "table_name" => "nc.d_so", "job" => "fluentd-plugin-kudu", "instance" => "mbp14pro.local" },
    { "message" => "Row Projector request submit failed: service unavailable: Thread pool is at capacity(1/1 tasks running , 100/100 tasks queued) [suppressed 79 similar messages]Proxy.cc:231] call had error, refreshing address and retrying: Remote error: Service unavailable: Update Consensus request on kudu.consensus. consensusService from 1.1.1.1:55108 dropped due to backpressure. The service queue is full; it has 50 items", "category" => "prometheus", "type" => "BACKPRESSURE", "metric-type" => "Counter", "metric-name" => "kudu_backpressure_count", "items" => "50", "current_running_tasks" => 1, "max_running_tasks" => 1, "current_queued_tasks" => 100, "max_queued_tasks" => 100, "job" => "fluentd-plugin-kudu", "instance" => "mbp14pro.local" },
    { "message" => "Failed to write batch of 6 ops to tablet after 1 attempt : Failed to write to server : Write RPC to  x.x.x.x:7050 timed out after 179.999 (ON_OUTBOUND_QUEUE)", "category" => "prometheus", "type" => "WRITER_TIMEOUT", "metric-type" => "Counter", "metric-name" => "kudu_write_batch_timeout_count", "job" => "fluentd-plugin-kudu", "instance" => "mbp14pro.local" }
  ]

  test "messages1_test" do
    driver = create_driver(CONFIG)
    driver.run(default_tag: "test") do
      messages.each do |message|
        driver.feed(message) # 로그 메시지를 주입
      end
    end

    puts Prometheus::Client::Formats::Text.marshal(Prometheus::Client.registry)
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::PrometheusOut).configure(conf)
  end
end
