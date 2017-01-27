require 'test_helper'

# extracted from ActiveSupport's MessageEncryptorTest after the GCM additions in
# https://github.com/rails/rails/commit/d4ea18a8cb84601509ee4c6dc691b212af8c2c36
class EncryptorTest < ActiveSupport::TestCase
  def setup
    @secret    = SecureRandom.random_bytes(32)
    @data = { :some => "data", :now => Time.local(2010) }
  end

  test "encryption" do
    encryptor = Encryptor.new(@secret)
    message = encryptor.encrypt(@data)
    assert_equal @data, encryptor.decrypt(message)
  end

  test "repeated encryption" do
    encryptor = Encryptor.new(@secret)
    first_message = encryptor.encrypt(@data)
    second_message = encryptor.encrypt(@data)
    assert_not_equal first_message, second_message
  end

  test "decryption failures" do
    encryptor = Encryptor.new(@secret)
    text, iv, auth_tag = encryptor.encrypt(@data).split("--")

    [
      [iv, text, auth_tag] * "--",
      [munge(text), iv, auth_tag] * "--",
      [text, munge(iv), auth_tag] * "--",
      [text, iv, munge(auth_tag)] * "--",
      [munge(text), munge(iv), munge(auth_tag)] * "--",
      [text, iv] * "--",
      [text, iv, auth_tag[0..-2]] * "--"
    ].each.with_index do |message, idx|
      assert_raise(Encryptor::InvalidMessage) do
        encryptor.decrypt(message)
      end
    end
  end

  private

  def assert_not_decrypted(value)
    assert_raise(Encryptor::InvalidMessage) do
      @encryptor.decrypt(value)
    end
  end

  def munge(base64_string)
    bits = ::Base64.strict_decode64(base64_string)
    bits.reverse!
    ::Base64.strict_encode64(bits)
  end
end
