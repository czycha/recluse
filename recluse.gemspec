# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'recluse/info'

Gem::Specification.new do |spec|
  spec.name          = 'recluse'
  spec.version       = Recluse::VERSION
  spec.authors       = ['James Anthony Bruno']
  spec.email         = ['j.bruno.che@gmail.com']

  spec.summary       = 'Friendly, neighborhood web crawler for quality assurance.'
  spec.homepage      = Recluse::URL
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'thor', '~> 0.19.1'
  spec.add_runtime_dependency 'mechanize', '~> 2.7.5'
  spec.add_runtime_dependency 'nokogiri', '~> 1.7.0.1'
  spec.add_runtime_dependency 'addressable', '~> 2.4.0'
  spec.add_runtime_dependency 'colorize', '~> 0.7.7'
  spec.add_runtime_dependency 'user_config', '~> 0.0.4'
  spec.add_runtime_dependency 'ruby-progressbar', '~> 1.8.1'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 0.47.1'
  spec.add_development_dependency 'minitest', '~> 5.10.1'
  spec.add_development_dependency 'minitest-reporters', '~> 1.1.14'
end
