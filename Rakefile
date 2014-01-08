require "bundler/gem_tasks"
require "rspec/core/rake_task"

task :default => ["specs:all"]

namespace :specs do
  desc "Run all specs"
  RSpec::Core::RakeTask.new(:all)

  # make a task for each *_spec.rb in spec/
  FileList["spec/*_spec.rb"].each do |path|
    ctx = File.basename(path, "*.rb").split("_").first
    
    desc "Run the #{ctx} spec"
    RSpec::Core::RakeTask.new(ctx) do |t|
      t.pattern = "spec/#{ctx}_spec.rb"
    end
  end
end
