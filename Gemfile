source 'https://rubygems.org'

gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
gem 'puma', '~> 3.0'
gem 'bcrypt', '~> 3.1.7'
gem 'rack-cors'
gem 'json-jwt'
gem 'zxcvbn-ruby', require: 'zxcvbn'
gem 'hiredis'
gem 'redis', require: ["redis", "redis/connection/hiredis"]
gem 'connection_pool'
gem 'sucker_punch'

# database driver loading is handled by parsing ENV['DATABASE_URL']
group :sqlite3 do
  gem 'sqlite3'
end
group :mysql do
  gem 'mysql2'
end
group :postgres do
  gem 'pg'
end

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
end

group :test do
  gem 'factory_girl_rails'
  gem 'minitest-stub_any_instance'
  gem 'webmock'
  gem 'timecop'
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
