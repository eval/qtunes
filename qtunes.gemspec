# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qtunes/version"

Gem::Specification.new do |s|
  s.name        = "qtunes"
  s.version     = Qtunes::VERSION
  s.authors     = ["Gert Goet"]
  s.email       = ["gert@thinkcreate.nl"]
  s.homepage    = ""
  s.summary     = %q{add songs to queue, let cmus eat it}
  s.description = %q{add songs to queue, let cmus eat it}

  s.rubyforge_project = "qtunes"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "shotgun"
  s.add_runtime_dependency "sinatra"
  s.add_runtime_dependency "rack-flash"
  s.add_runtime_dependency "thor"
  s.add_runtime_dependency "cocaine"
  s.add_runtime_dependency "ruby-audioinfo"
end
