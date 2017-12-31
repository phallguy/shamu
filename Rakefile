require "bundler/gem_tasks"

desc "Run the specs"
task :specs do
  system "rspec"
end

desc "Run linters on the codebase"
task :lint do
  system "bundle exec rubocop -S -D --config .rubocop.yml"
end

task :default => [ :lint, :specs ]
task :release => [ :default ]
