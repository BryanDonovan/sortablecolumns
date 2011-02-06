# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sortablecolumns/version"

Gem::Specification.new do |s|
  s.name        = "sortablecolumns"
  s.version     = Sortablecolumns::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Bryan Donovan"]
  s.email       = ["b.dondo+rubyforge@gmail.com"]
  s.homepage    = "http://rubyforge.org/projects/sortablecolumns/"
  s.summary     = "Sortable HTML tables for Rails"
  s.description = "Sortable HTML tables for Rails"

  s.rubyforge_project = "sortablecolumns"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

	s.add_dependency "activerecord", ">=3.0.3"
	s.add_dependency "activesupport", ">=3.0.3"
	s.add_dependency "actionpack", ">=3.0.3"
end
