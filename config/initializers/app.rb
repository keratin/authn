# currently only supports RSA 256
if Rails.env.test?
  keypair = OpenSSL::PKey::RSA.new(512)
  private_key = keypair.to_s
  public_key = keypair.public_key.to_s
elsif ENV['RSA_PUBLIC_KEY'] && ENV['RSA_PRIVATE_KEY']
  private_key = ENV['RSA_PRIVATE_KEY'].gsub('\n', "\n")
  public_key = ENV['RSA_PUBLIC_KEY'].gsub('\n', "\n")
end
Rails.application.config.auth_private_key = OpenSSL::PKey::RSA.new(private_key)
Rails.application.config.auth_public_key = OpenSSL::PKey::RSA.new(public_key)
Rails.application.config.auth_signing_alg = 'RS256'

# This setting controls how long the access tokens will live. Applications can and should implement
# a periodic token exchange process to keep the effective session alive much longer than the expiry
# listed here.
#
# This is an important precaution because it allows the authentication server to revoke sessions
# (e.g. on logout) with confidence that any related access tokens will expire soon and limit any
# potential damage from exposure.
#
# # Background
#
# The client maintains two sessions. The first is a session with the authentication service, and the
# second is with the application.
#
# The applications do not want a chatty protocol requiring them to verify authentication tokens over
# the network on every request, so we generate access tokens that they can verify and trust by
# themselves after fetching and storing our public key. This effectively becomes the application
# session.
#
# But the authentication service does not want to lose the ability to revoke tokens. So it makes the
# access tokens relatively short-lived (e.g. 1.hour). Then, it compensates by allowing clients to
# fetch a fresh access token at any time -- ideally before the current access token expires. This is
# an easy process because the client's session with the authentication service does not expire, and
# generating a new access token from that session is quite painless.
#
# Note that this expiry also creates an effective timeout period where anyone who closes the app and
# stops refreshing the session will find themselves logged out (holding an outdate session token)
# when they return.
Rails.application.config.access_token_expiry = ENV.fetch('ACCESS_TOKEN_TTL', 1.hour.to_i)

# This setting controls how long we keep refresh tokens after their last touch. This is necessary to
# prevent years-long Redis bloat from inactive sessions, where users close the window rather than
# log out.
Rails.application.config.refresh_token_expiry = ENV.fetch('REFRESH_TOKEN_TTL', 1.year.to_i)

Rails.application.config.application_domains = ENV['APP_DOMAINS'].split(',')

# will be used as issuer for id tokens, and must be a URL that the application can resolve in order
# to fetch our public key for JWT verification.
#
# e.g. https://auth.service
Rails.application.config.authn_url = ENV['AUTHN_URL']

# minimum complexity score from the zxcvbn algorithm, where:
#
# * 0 - too guessable
# * 1 - very guessable
# * 2 - somewhat guessable
# * 3 - safely unguessable
# * 4 - very unguessable
#
# see: https://blogs.dropbox.com/tech/2012/04/zxcvbn-realistic-password-strength-estimation/
Rails.application.config.minimum_password_score = ENV.fetch('PASSWORD_POLICY_SCORE', 2)

# full urls for endpoints we need to communicate with the main application.
#
# for security, each url in production should use https and include a http basic auth username &
# password.
Rails.application.config.application_endpoints = {}.tap do |routes|
  if ENV['APP_PASSWORD_RESET_URL']
    routes[:password_reset_uri] = URI.parse(ENV['APP_PASSWORD_RESET_URL'])
  end
end

# how long is a password reset token valid?
Rails.application.config.password_reset_expiry = ENV.fetch('PASSWORD_RESET_TOKEN_TTL', 30.minutes.to_i)

# the time zone for tracking and reporting daily/weekly/yearly actives.
Rails.application.config.statistics_time_zone = Time.find_zone!(ENV.fetch('TIME_ZONE', 'UTC'))
Rails.application.config.daily_actives_retention = ENV.fetch('DAILY_ACTIVES_RETENTION', 365)  # one year
Rails.application.config.weekly_actives_retention = ENV.fetch('WEEKLY_ACTIVES_RETENTION', 104) # two years

# The credentials necessary to access private API endpoints.
# This should be paired with TLS.
Rails.application.config.api_username = ENV.fetch('HTTP_AUTH_USERNAME', rand(9999999).to_s)
Rails.application.config.api_password = ENV.fetch('HTTP_AUTH_PASSWORD', rand(9999999).to_s)

# BCrypt costs describe how many times the password should be hashed. Costs are exponential, and may
# be increased later without waiting for a user to return and log in.
#
# The ideal cost is the slowest one that can be performed without login feeling slow and without
# creating CPU bottlenecks or easy DDOS attacks on your AuthN server. There's no reason to go below
# 10, and 12 starts to become noticeable.
#
# A cost of 10 is 1024 (2^10) iterations, and takes ~0.067 seconds on my laptop.
# A cost of 11 is 2048 (2^11) iterations, and takes ~0.136 seconds on my laptop.
# A cost of 12 is 4096 (2^12) iterations, and takes ~0.276 seconds on my laptop.
BCrypt::Engine.cost = [10, ENV.fetch('BCRYPT_COST', 11).to_i].max

#
Rails.application.config.email_usernames = ENV.fetch('USERNAME_IS_EMAIL', false).to_s.downcase.in? ['t', 'true', 'yes']
