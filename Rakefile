require "bundler/gem_tasks"

desc "Run the specs"
task :specs do
  system "rspec"
end

namespace :lint do
  desc "Run linters on the codebase"
  task :run do
    system "bundle exec rubocop -S -D --config .rubocop.yml"
  end

  desc "Run linters on the codebase and auto correct is possible"
  task :clean do
    system "bundle exec rubocop -S -D --safe-auto-correct --config .rubocop.yml"
  end
end

desc "Run linters on the codebase"
task :lint => "lint:run"

task :default => [ :lint, :specs ]
task :release => [ :default ]
