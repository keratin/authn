source 'https://rubygems.org'

gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
gem 'sqlite3'
gem 'puma', '~> 3.0'
gem 'bcrypt', '~> 3.1.7'
gem 'rack-cors'
gem 'json-jwt'
gem 'zxcvbn-ruby', require: 'zxcvbn'
gem 'hiredis'
gem 'redis', require: ["redis", "redis/connection/hiredis"]
gem 'connection_pool'

group :development, :test do
  gem 'byebug', platform: :mri
end

group :test do
  gem 'factory_girl_rails'
  gem 'minitest-stub_any_instance'
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
