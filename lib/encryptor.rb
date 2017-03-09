require 'openssl'
require 'base64'

# Extracted from ActiveSupport's MessageEncryptor after the GCM additions in
# https://github.com/rails/rails/commit/d4ea18a8cb84601509ee4c6dc691b212af8c2c36
class Encryptor
  CIPHER = 'aes-256-gcm'

  class InvalidMessage < StandardError; end
  OpenSSLCipherError = OpenSSL::Cipher::CipherError

  # Initialize a new Encryptor. +secret+ must be at least as long as the cipher key size. You can
  # generate a suitable key by using <tt>ActiveSupport::KeyGenerator</tt> or a similar key
  # derivation function.
  def initialize(secret)
    @secret = secret
    @serializer = Marshal
  end

  def encrypt(value)
    cipher = OpenSSL::Cipher.new(CIPHER)
    cipher.encrypt
    cipher.key = @secret

    # Rely on OpenSSL for the initialization vector
    iv = cipher.random_iv
    cipher.auth_data = ''

    encrypted_data = cipher.update(@serializer.dump(value))
    encrypted_data << cipher.final

    blob = "#{::Base64.strict_encode64 encrypted_data}--#{::Base64.strict_encode64 iv}"
    blob << "--#{::Base64.strict_encode64 cipher.auth_tag}"
    blob
  end

  def decrypt(encrypted_message)
    cipher = OpenSSL::Cipher.new(CIPHER)
    encrypted_data, iv, auth_tag = encrypted_message.split('--'.freeze).map{|v| ::Base64.strict_decode64(v) }

    # Currently the OpenSSL bindings do not raise an error if auth_tag is
    # truncated, which would allow an attacker to easily forge it. See
    # https://github.com/ruby/openssl/issues/63
    raise InvalidMessage if auth_tag.nil? || auth_tag.bytes.length != 16

    cipher.decrypt
    cipher.key = @secret
    cipher.iv  = iv
    cipher.auth_tag = auth_tag
    cipher.auth_data = ''

    decrypted_data = cipher.update(encrypted_data)
    decrypted_data << cipher.final

    @serializer.load(decrypted_data)
  rescue OpenSSLCipherError, TypeError, ArgumentError
    raise InvalidMessage
  end
end
