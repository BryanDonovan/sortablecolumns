# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bundletest/version"

=begin
  p.name = "sortablecolumns"
  p.author = "Bryan Donovan - http://www.bryandonovan.com"
  p.email = "b.dondo+rubyforge@gmail.com"
  p.description = "Sortable HTML tables for Rails"
  p.summary = "Sortable HTML tables for Rails"
  p.url = "http://rubyforge.org/projects/sortablecolumns/"
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.remote_rdoc_dir = '' # Release to root
=end

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
end
