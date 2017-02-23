require 'bundler/gem_tasks'
require 'rake/testtask'
require 'fileutils'

task default: :spec

task :rubocop do
  sh('rubocop -aSE') { |ok, res| }
end

namespace :test do
  desc 'Setup test environment'
  task :before do
    $stderr.puts 'Starting server'
    out_log = './test/site/logs/httpd-out.log'
    err_log = './test/site/logs/httpd-err.log'
    FileUtils.touch(out_log) unless File.exist?(out_log)
    FileUtils.touch(err_log) unless File.exist?(err_log)

    @server = Process.spawn(
      'ruby -run -e httpd ./test/site/ -p 9533',
      in: :close,
      out: out_log,
      err: err_log
    )
    sleep 1
  end

  Rake::TestTask.new(:run) do |t|
    t.pattern = 'test/*.rb'
    t.verbose = false
  end

  desc 'Teardown test environment'
  task :after do
    $stderr.puts 'Stopping server'
    Process.kill 'TERM', @server
  end
end

task :test do
  Rake::Task['test:before'].invoke
  begin
    Rake::Task['test:run'].invoke
  ensure
    Rake::Task['test:after'].invoke
  end
end
