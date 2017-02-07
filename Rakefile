require 'bundler/gem_tasks'
require 'rake/testtask'

task default: :spec

task :rubocop do
  sh('rubocop -aSE') { |ok, res| }
end

Rake::TestTask.new do |t|
  t.pattern = 'test/*.rb'
  t.verbose = true
end
