# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "excavator/version"

Gem::Specification.new do |s|
  s.name        = "excavator"
  s.version     = Excavator::VERSION
  s.authors     = ["Peter Bui"]
  s.email       = ["peter@paydrotalks.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "excavator"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "minitest", ">= 2.10.0"
  s.add_development_dependency "ruby-debug19"
  s.add_development_dependency "rake"
end
