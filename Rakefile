# -*- ruby -*-

require 'rubygems'
#require 'hoe'
require './lib/sortablecolumns.rb'
require 'bundler'
Bundler::GemHelper.install_tasks

=begin
Hoe.new('sortablecolumns', Sortablecolumns::VERSION) do |p|
  p.name = "sortablecolumns"
  p.author = "Bryan Donovan - http://www.bryandonovan.com"
  p.email = "b.dondo+rubyforge@gmail.com"
  p.description = "Sortable HTML tables for Rails"
  p.summary = "Sortable HTML tables for Rails"
  p.url = "http://rubyforge.org/projects/sortablecolumns/"
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.remote_rdoc_dir = '' # Release to root
end

=end

rule '' do |t|
  system "cd test && ruby sortablecolumns_test.rb"
end

ALLISON = "/opt/local/lib/ruby/gems/1.8/gems/allison-2.0.3/lib/allison.rb"

Rake::RDocTask.new do |rd|  
  rd.main = "README.txt"  
  rd.rdoc_dir = "doc"  
  rd.rdoc_files.include(  
      "README.txt",  
      "History.txt",  
      "Manifest.txt",  
      "lib/**/*.rb")  
  rd.title = "SortableColumns RDoc"  

  rd.options << '-S' # inline source  

  rd.template = ALLISON if File.exist?(ALLISON)  
end  

# vim: syntax=Ruby
