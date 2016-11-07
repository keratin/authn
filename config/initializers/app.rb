# currently only supports RSA 256
key_path = ENV['KEY_PATH'] || Rails.root.join('config', 'id_rsa').to_s
Rails.application.config.auth_private_key = OpenSSL::PKey::RSA.new(File.read(key_path))
Rails.application.config.auth_public_key = OpenSSL::PKey::RSA.new(File.read(key_path + '.pub'))
Rails.application.config.auth_expiry = 1.hour.to_i

Rails.application.config.client_hosts = [ENV['TRUSTED_HOST']]

Rails.application.config.auth_signing_alg = 'RS256'
