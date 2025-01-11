require "fluent/plugin/output"
require 'rufus-scheduler'
require 'prometheus/client'
require 'prometheus/client/push'
require 'net/http'
require 'uri'
require 'socket'

########################################
## 이 테스트 코드를 윈도에서 실행하기 위해서는
# TZ 환경변수에 Asia/Seoul을 설정합니다.
########################################

module Fluent
  module Plugin
    class PrometheusOut < Fluent::Plugin::Output
      Fluent::Plugin.register_output("prometheus-pushgateway", self)

      attr_accessor :engine, :scheduler, :registry, :gateway_server, :job, :gateway, :instance

      def configure(conf)
        super
        $log.info "Prometheus Output Configure Started"

        @instance = conf["hostname"] || Socket.gethostname
        @gateway_server = conf["gateway"]
        @job = conf["job"]

        $log.info "Prometheus Push Gateway Configuration : #{conf}"

        @registry = Prometheus::Client.registry
        @gateway = Prometheus::Client::Push.new(job: @job, gateway: "http://#{@gateway_server}")

        $log.info "Prometheus Push Gateway: #{@gateway_server}"
        $log.info "Prometheus Job: #{@job}"
        $log.info "Prometheus Instance: #{@instance}"
        $log.info "Prometheus Push Gateway Connector Created"

        @scheduler = Rufus::Scheduler.new
        $log.info "Rufus Scheduler Started"

        @scheduler.every '15s' do
          @gateway.add(registry)

          $log.info "Pushing to Prometheus Push Gateway: http://#{@gateway_server}"
        end
      end

      def to_symbol(obj)
        if obj.is_a?(Symbol)
          # Symbol인 경우 그대로 사용
          obj
        else
          # Symbol로 변경
          obj.to_sym
        end
      end

      def process(tag, records)
        # 메시지가 유입되면 Prometheus Metric을 생성하고 처리한다.
        # 대부분은 Counter이므로 increment 처리를 하지만 Gauge는 값을 Setting해야 한다.
        records.each do |time, record|
          if @registry.get(record["metric-name"]).nil?
            @registry.counter(to_symbol(record["metric-name"]), docstring: record["metric-desc"], labels: [:type, :instance, :source])
          end

          m = @registry.get(record["metric-name"])
          m.increment(labels: { type: record["type"], instance: @instance, source: @job })

          $log.debug "Prometheus Metric: #{m.inspect}"
        end
      end

      def generate_metrics_text
        Prometheus::Client::Formats::Text.marshal(Prometheus::Client.registry)
      end
    end
  end
end
