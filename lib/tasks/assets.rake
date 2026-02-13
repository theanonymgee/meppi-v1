# frozen_string_literal: true

# Define assets:precompile task for Rails 7.1 compatibility with tailwindcss-rails
# Rails 7.1 removed sprockets by default, but tailwindcss-rails expects this task

# Define the task BEFORE tailwindcss tries to enhance it
unless Rake::Task.task_defined?("assets:precompile")
  namespace :assets do
    task :precompile do
      # This is a placeholder task
      # tailwindcss:build will be enhanced onto this task
    end
  end
end
