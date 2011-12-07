# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "porter/version"

Gem::Specification.new do |s|
  s.name        = "porter"
  s.version     = Porter::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kenny Johnston", "Robert Bousquet"]
  s.email       = ["kjohnston.ca@gmail.com"]
  s.homepage    = "http://github.com/kjohnston/porter"
  s.summary     = %q{Capistrano and Rake tasks for cloning production and/or staging databases and assets to development.}
  s.description = %q{Capistrano and Rake tasks for cloning production and/or staging databases and assets to development.}

  s.add_runtime_dependency "capistrano",     ">= 2.5.0"
  s.add_runtime_dependency "capistrano-ext", ">= 1.2.0"
  s.add_runtime_dependency "rake",           ">= 0.8.7"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
