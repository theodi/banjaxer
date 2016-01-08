# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'banjaxer/version'

Gem::Specification.new do |spec|
  spec.name          = 'banjaxer'
  spec.version       = Banjaxer::VERSION
  spec.authors       = ['pikesley']
  spec.email         = ['sam.pikesley@theodi.org']

  spec.summary       = 'Demo gem for testing Thor apps with Rspec'
  spec.description   = 'Why is this line even here?'
  spec.homepage      = 'http://github.com/theodi/banjaxer'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 0.19'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'vcr', '~> 3.0'
  spec.add_development_dependency 'timecop', '~> 0.8'
  spec.add_development_dependency 'coveralls', '~> 0.8'
end
