PasswordScorer = Struct.new(:password) do
  # using a singleton for the tester means that we preload dictionary data on boot
  # and save that performance cost when testing individual passwords. it makes a
  # significant difference even during tests.
  TESTER = Zxcvbn::Tester.new

  # SECURITY NOTE:
  #
  # this password complexity algorithm is expensive and scales exponentially to the length of the
  # provided string. we mitigate simple DoS attacks by only considering the first 72 characters of
  # the password, which is also bcrypt's limit.
  def perform
    if password.present?
      TESTER.test(password[0, 72]).score
    else
      0
    end
  end
end
