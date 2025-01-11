require "helper"
require "fluent/plugin/out_prometheus.rb"
require 'net/http'
require 'uri'

class PrometheusOutTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  CONFIG = { "gateway" => "localhost:9091", "job" => "impala-kudu-metrics" }

  messages = [
    {
      "message" => "Unable to open scanner for node with id ‘0’ for Kudu table ‘nc.d_so’ : Time out : exceeded configured scan timeout of 180.000s: Scan RPC to x.x.x.x:7050 timed out after 179.999 (ON_OUTBOUND_QUEUE)",
      "category" => "prometheus",
      "type" => "TIMEOUT",
      "metric-type" => "Counter",
      "metric-name" => "collect_kudu_scan_timeout_count",
      "metric-prefix" => "collect_kudu_scan_timeout",
      "metric-desc" => "Kudu Scan Timeout 건수",
      "attr_table_name" => "nc.d_so"
    },
    {
      "message" => "Row Projector request submit failed: service unavailable: Thread pool is at capacity(1/1 tasks running , 100/100 tasks queued) [suppressed 79 similar messages]Proxy.cc:231] call had error, refreshing address and retrying: Remote error: Service unavailable: Update Consensus request on kudu.consensus. consensusService from 1.1.1.1:55108 dropped due to backpressure. The service queue is full; it has 50 items",
      "category" => "prometheus",
      "type" => "RESOURCE",
      "metric-type" => "Counter",
      "metric-name" => "collect_kudu_backpressure_count",
      "metric-prefix" => "collect_kudu_backpressure",
      "metric-desc" => "Kudu Backpressure 건수",
      "metric_service_queue_items" => 50,
      "metric_current_running_tasks" => 1,
      "metric_max_running_tasks" => 1,
      "metric_current_queued_tasks" => 100,
      "metric_queued_tasks" => 100,
      "metric_max_queued_tasks" => 30
    },
    {
      "message" => "Failed to write batch of 6 ops to tablet after 1 attempt : Failed to write to server : Write RPC to  x.x.x.x:7050 timed out after 179.999 (ON_OUTBOUND_QUEUE)",
      "category" => "prometheus",
      "type" => "TIMEOUT",
      "metric-type" => "Counter",
      "metric-name" => "collect_kudu_write_batch_timeout_count",
      "metric-prefix" => "collect_kudu_write_batch_timeout",
      "metric-desc" => "Kudu Client Timeout 건수"
    }
  ]

  test "messages1_test" do
    # 단위 테스트를 위해서 create_driver로 전달하기 위해서 Hash를 String으로 변환한다.
    conf = CONFIG.map { |key, value| "#{key} #{value}" }.join("\n")
    puts "Driver Configuration : \n#{conf}"

    driver = create_driver(conf)
    driver.run(default_tag: "test") do
      messages.each do |message|
        driver.feed(message) # 로그 메시지를 주입
      end
    end

    registry = Prometheus::Client.registry
    gateway = Prometheus::Client::Push.new(job: CONFIG["job"], gateway: "http://#{CONFIG["gateway"]}")

    gateway.add(registry)
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::PrometheusOut).configure(conf)
  end
end
