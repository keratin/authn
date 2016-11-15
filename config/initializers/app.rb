# currently only supports RSA 256
key_path = ENV['KEY_PATH'] || Rails.root.join('config', 'id_rsa').to_s
Rails.application.config.auth_private_key = OpenSSL::PKey::RSA.new(File.read(key_path))
Rails.application.config.auth_public_key = OpenSSL::PKey::RSA.new(File.read(key_path + '.pub'))
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
Rails.application.config.access_token_expiry = 1.hour.to_i

# This setting controls how long we keep refresh tokens after their last touch. This is necessary to
# prevent years-long Redis bloat from inactive sessions, where users close the window rather than
# log out.
Rails.application.config.refresh_token_expiry = 1.year.to_i

Rails.application.config.client_hosts = [ENV['TRUSTED_HOST']]

# will be used as issuer for id tokens, and must be a URL that the application can resolve in order
# to fetch our public key for JWT verification.
#
# e.g. https://auth.service
Rails.application.config.base_url = ENV['BASE_URL']

# minimum complexity score from the zxcvbn algorithm, where:
#
# * 0 - too guessable
# * 1 - very guessable
# * 2 - somewhat guessable
# * 3 - safely unguessable
# * 4 - very unguessable
#
# see: https://blogs.dropbox.com/tech/2012/04/zxcvbn-realistic-password-strength-estimation/
Rails.application.config.minimum_password_score = 2

# full urls for endpoints we need to communicate with the main application.
#
# for security, each url in production should use https and include a http basic auth username &
# password.
Rails.application.config.application_endpoints = {
  password_reset_uri: URI.parse(ENV['PASSWORD_RESET_URL'])
}

# how long is a password reset token valid?
Rails.application.config.password_reset_expiry = 30.minutes

# the time zone for tracking and reporting daily/weekly/yearly actives.
Rails.application.config.statistics_time_zone = Time.find_zone!('UTC')
Rails.application.config.daily_actives_retention = 365  # one year
Rails.application.config.weekly_actives_retention = 104 # two years
