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
          labels = { type: record["type"], instance: @instance, source: @job }

          # attr_ 로 시작하는 Attribute는 Prometheus Metric의 Label로 설정한다.
          # Prometheus는 Metric 생성 후에는 Label을 변경할 수 없다.
          # record.keys.each { |key|
          #   if key.start_with?("attr_")
          #     label_name = key.sub(/^attr_/, "")
          #     label_value = record[key]
          #     labels[label_name.to_sym] = label_value
          #   end
          # }

          m.increment(labels: labels)

          prefix = record["metric-prefix"]
          record.keys.each { |key|
            if key.start_with?("metric_")
              label_name = key.sub(/^metric_/, "")
              label_value = record[key]

              metric_name = "#{prefix}_#{label_name}"
              metric_desc = metric_name.sub(/^_/, " ")
              if @registry.get(metric_name).nil?
                @registry.gauge(to_symbol(metric_name), docstring: metric_desc, labels: [:type, :instance, :source])
              end
              g = @registry.get(metric_name)
              g.set(label_value, labels: labels)
            end
          }

          $log.debug "Prometheus Metric: #{m.inspect}"
        end
      end

      def generate_metrics_text
        Prometheus::Client::Formats::Text.marshal(Prometheus::Client.registry)
      end
    end

    def push_to_gateway(metrics_text)
      uri = URI.parse("http://#{@gateway}/metrics/job/#{@job}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Put.new(uri.path)
      request.body = metrics_text
      request['Content-Type'] = 'text/plain'

      response = http.request(request)
      $log.debug "Response from Push Gateway: #{response.code} #{response.message}"
    rescue StandardError => e
      $log.warn "Failed to push metrics to Push Gateway: #{e.message}"
    end
  end
end
