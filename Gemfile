source 'https://rubygems.org'

gem 'bcrypt', '~> 3.1.7'
gem 'connection_pool'
gem 'hiredis'
gem 'json-jwt'
gem 'puma', '~> 3.0'
gem 'rack-cors'
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
gem 'redis', require: ['redis', 'redis/connection/hiredis']
gem 'sucker_punch'
gem 'zxcvbn-ruby', require: 'zxcvbn'

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
  gem 'timecop'
  gem 'webmock'
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
