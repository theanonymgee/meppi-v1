source 'https://rubygems.org'

ruby '3.2.3'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.0'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Add pgvector for semantic search/RAG
gem 'pgvector', '~> 0.2'
# Use sqlite3 for data import from legacy databases
gem 'sqlite3', '~> 1.4'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem 'rack-cors'

# API Gems
gem 'blueprinter', '~> 1.0'
gem 'pagy', '~> 6.0'
gem 'faraday', '~> 2.0'

# Frontend
gem 'turbo-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.3'
gem 'importmap-rails', '~> 1.2'
gem 'tailwindcss-rails', '~> 2.0'
gem 'sprockets-rails', '~> 3.4'

gem "dotenv-rails"
group :development, :test do
  # Testing
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 3.2'
  gem 'rspec-rails', '~> 6.0'
  gem 'shoulda-matchers', '~> 5.3'

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows]
  gem 'pry-rails'
end

group :development do
  # Development tools
  gem 'annotate', '~> 3.2'
  gem 'bullet', '~> 7.1'
  gem 'rubocop', '~> 1.60', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', '~> 2.25', require: false

  # Security scanning
  gem 'brakeman', require: false

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Code coverage
  gem 'simplecov', require: false

  # VCR for HTTP request recording
  gem 'vcr'
  gem 'webmock'
end

# BGE-M3 Embeddings (local inference)
# Use transformers.rb for BGE-M3 model
# gem 'torch-rb'  # LibTorch binding (optional, for full PyTorch support)
# gem 'sentence-transformers'  # Alternative approach
gem "selenium-webdriver"
