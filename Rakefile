# -*- ruby -*-

require 'rubygems'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rcov'
require 'rcov/rcovtask'
require './lib/sortablecolumns.rb'
require 'bundler'
Bundler::GemHelper.install_tasks

desc "Run unit tests"
Rake::TestTask.new("test") do |t|
  t.libs << "test"
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

desc "Run unit tests with rcov"
Rcov::RcovTask.new('rcov') do |t|
  t.test_files = FileList['test/*_test.rb']
  t.ruby_opts << "-Ilib:ext/rcovrt" # in order to use this rcov
  t.verbose = true
end

Rake::RDocTask.new do |rd|  
  rd.main = "README.txt"  
  rd.rdoc_dir = "doc"  
  rd.rdoc_files.include(  
      "README.txt",  
      "History.txt",  
      "Manifest.txt",  
      "lib/**/*.rb")  
  rd.title = "Sortablecolumns RDoc"  

  rd.options << '-S' # inline source  
end  

# vim: syntax=Ruby
