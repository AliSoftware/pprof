require File.expand_path('lib/pprof/version', File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name        = 'pprof'
  s.version     = PProf::VERSION
  s.summary     = 'A Provisioning Profiles library'
  s.description = 'library and binary tool to manipulate Provisioning Profile files'
  s.authors     = ['Olivier Halligon']
  s.email       = 'olivier@halligon.net'
  s.homepage    = 'https://github.com/AliSoftware/pprof'
  s.license     = 'MIT'

  s.files       = Dir['lib/**/*'] + Dir['bin/**/*'] + %w[README.md LICENSE]
  s.required_ruby_version = '>= 2.0.0'
  s.executables << 'pprof'

  s.add_dependency 'plist', '~> 3.1'
end
