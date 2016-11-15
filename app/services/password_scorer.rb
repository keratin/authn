PasswordScorer = Struct.new(:password) do
  # SECURITY NOTE:
  #
  # this password complexity algorithm is expensive and scales exponentially to the length of the
  # provided string. we mitigate simple DoS attacks by only considering the first 72 characters of
  # the password, which is also bcrypt's limit.
  def perform
    if password.present?
      Zxcvbn.test(password[0, 72]).score
    else
      0
    end
  end
end
