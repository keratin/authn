# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins *Rails.application.config.application_domains
    resource "#{Rails.application.config.mounted_path.chomp('/')}/accounts", methods: [:post], headers: :any
    resource "#{Rails.application.config.mounted_path.chomp('/')}/accounts/available", methods: [:post], headers: :any
    resource "#{Rails.application.config.mounted_path.chomp('/')}/sessions", methods: [:post], headers: :any
    resource "#{Rails.application.config.mounted_path.chomp('/')}/sessions/refresh", methods: [:get], headers: :any
    resource "#{Rails.application.config.mounted_path.chomp('/')}/password/reset", methods: [:get], headers: :any
    resource "#{Rails.application.config.mounted_path.chomp('/')}/password", methods: [:post], headers: :any
  end
end
