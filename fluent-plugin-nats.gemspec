# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "fluent-plugin-nats"
  gem.version     = File.read("VERSION").strip 
  gem.authors     = ["Eduardo Aceituno"]
  gem.email       = ["achied@gmail.com"]
  gem.homepage    = "https://github.com/achied/fluent-plugin-nats"
  gem.summary     = %q{nats plugin for fluentd, an event collector}
  gem.description = %q{nats plugin for fluentd, an event collector}

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_dependency "fluentd", ">= 0.10.7", "< 0.14"
  gem.add_dependency "nats", ">= 0.4.22"
  gem.add_dependency "eventmachine", ">= 0.12.10"
  
  gem.add_development_dependency "rake", ">= 0.9.2"
end
