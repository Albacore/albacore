require 'bundler/setup'
Bundler::GemHelper.install_tasks

task :default => :'specs:all'

namespace :specs do
  require 'rspec/core/rake_task'

  desc "Run all specs"
  RSpec::Core::RakeTask.new(:all)

  # generate tasks for each *_spec.rb file in the root spec folder
  exceptNCov = []
  FileList['spec/*_spec.rb'].each do |fname|
    spec = $1 if /spec\/(.+)_spec\.rb/ =~ fname
    exceptNCov << spec unless /ncover|ndepend/ =~ spec
    desc "Run the #{spec} spec"
    RSpec::Core::RakeTask.new spec do |t|
      t.pattern = "spec/#{spec}*_spec.rb"
    end
  end

  desc "Run specs:all except :ncover, :ndepend"
  task :except_ncover => exceptNCov
end
