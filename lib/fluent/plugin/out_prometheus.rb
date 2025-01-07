require "fluent/plugin/output"
require 'rufus-scheduler'
require 'prometheus/client'
require 'prometheus/client/push'
require 'net/http'
require 'uri'

module Fluent
  module Plugin
    class PrometheusOut < Fluent::Plugin::Output
      Fluent::Plugin.register_output("prometheus", self)

      attr_accessor :engine, :scheduler, :registry, :gateway, :job

      def configure(conf)
        super
        print "Configure Started\n"

        @gateway = conf["gateway"]
        @job = conf["job"]

        print "Prometheus Push Gateway: #{@gateway}\n"
        print "Prometheus Job: #{job}\n"

        @scheduler = Rufus::Scheduler.new
        @registry = Prometheus::Client.registry

        @scheduler.every '15s' do
          puts "Pushing to Prometheus Push Gateway: #{@gateway}"

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
        records.each do |time, record|
          labels = { type: record["type"], instance: record["instance"], source: record["job"] }
          if @registry.get(record["metric-name"]).nil?
            @registry.counter(to_symbol(record["metric-name"]), docstring: record["metric-name"], labels: [:type, :instance, :source])
          end

          m = @registry.get(record["metric-name"])
          m.increment(labels: labels)
        end
        push_to_gateway(generate_metrics_text)
      end

      def generate_metrics_text
        Prometheus::Client::Formats::Text.marshal(Prometheus::Client.registry)
      end

      def push_to_gateway(metrics_text)
        uri = URI.parse("http://#{@gateway}/metrics/job/#{@job}")
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Put.new(uri.path)
        request.body = metrics_text
        request['Content-Type'] = 'text/plain'

        response = http.request(request)
        puts "Response from Push Gateway: #{response.code} #{response.message}"
      rescue StandardError => e
        puts "Failed to push metrics to Push Gateway: #{e.message}"
      end
    end
  end
end