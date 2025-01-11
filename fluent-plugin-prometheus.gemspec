lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name = "fluent-plugin-prometheus"
  s.version = "0.1.0"
  s.authors = ["김병곤"]
  s.email = ["fharenheit@gmail.com"]

  s.summary = %q{Fluentd Plugin for pushing metrics to Prometheus}
  s.description = %q{Fluentd Plugin for pushing metrics to Prometheus}
  s.homepage = "http://www.opencloudengine.org"
  s.license = "Apache-2.0"

  s.files = Dir['lib/**/*', 'spec/**/*', 'vendor/**/*', '*.gemspec', '*.md', 'CONTRIBUTORS', 'Gemfile', 'LICENSE', 'NOTICE.TXT']
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files = s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 2.6.2"
  s.add_development_dependency "rake", "~> 13.0.6"
  s.add_development_dependency "test-unit", "~> 3.5.9"
  s.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
  s.add_runtime_dependency "prometheus-client", "~> 4.2.3"
  s.add_runtime_dependency "rufus-scheduler", "~> 3.9.2"
  s.add_runtime_dependency "httpx", "~> 1.4.0"
end
