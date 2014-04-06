# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = 'bio-biostars-analytics'
  gem.homepage = 'http://github.com/joejimbo/bioruby-biostars-analytics'
  gem.license = 'MIT'
  gem.summary = %Q{Biostars data-mining and statistical analysis.}
  gem.description = %Q{Ruby script for data-mining biostars.org using web-crawling techniques as well as utilizing the Biostars RESTful API. Statistical analysis requires R (http://www.r-project.org).}
  gem.email = 'joachim.baran@gmail.com'
  gem.authors = [ 'Joachim Baran' ]
  gem.executables = [ 'biostars-analytics', 'biostar_api_stats', 'biostar_crawled_stats' ]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "bio-biostars-analytics #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
