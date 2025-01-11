require "helper"
require 'net/http'
require 'uri'

require "httpx"
require "json"

include HTTPX

class HttpxTest < Test::Unit::TestCase
  setup do
  end

  test "messages1_test" do
    client = Session.new
    request = client.build_request("POST", "http://nghttp2.org/httpbin/post", json: { "bang" => "bang" })
    res = client.request(request)

    puts "status: #{res.status}"
    puts "headers: #{res.headers}"
    puts "body: #{JSON.parse(res.body.to_s)}"

  end
end
