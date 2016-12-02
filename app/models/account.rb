class Account < ApplicationRecord
  # these are bcrypt hashes for an empty string, useful for performing
  # fake comparisons to mitigate timing attacks.
  EMPTY_PASSWORDS = {
    4 => "$2a$04$riUL94VEMOJwUfFkCUy8QO7HEL5L3uqUusOMELp509TuCWWJNuQG2",
    5 => "$2a$05$ycxVnxU5nSjeg1BAf68nHuzhGiEdxzYLZ9U6W8xXcYi4R2kQpjucu",
    6 => "$2a$06$8e.e6D8XF1GiLUV/LAidk.ar9LKx92m/0ELAGB5t5RofAKF.aHe8i",
    7 => "$2a$07$KWfZnK0J8rw1KVcf/JMgPO6OLQkLIlkopK4hvGdtmEaSNoNpdVeZa",
    8 => "$2a$08$xiz64CyXsr6CBMNrvbFxAO8SlV5ai0vQ9nW/AQRANoUwgjpbjuUYe",
    9 => "$2a$09$hvsYU7qQB1Gn5ZHtJFca..UzTvYaSrmYkZgfuSlArYS3Yza4laP36",
    10 => "$2a$10$1hP23Pl/f58gGNZeHHm80uqxrWUdALYVfp8aucGBmQiVRemEhZI7i",
    11 => "$2a$11$GxV0LDD.xwM0ItzfbuMEDeMihmkIjs0Si6x6zhZtAAlm3p.6/3Z6q",
    12 => "$2a$12$w58M3IGXURRAqXQ/OAsMmuqcV4YqP3WyJ.yHvHI5ANUK1bRWxeceK"
  }

  scope :named, ->(username) { where(username: username) }
  scope :active, ->{ where(deleted_at: nil) }

  before_save :set_password_changed_at

  def authenticate(given_password)
    BCrypt::Password.new(self.password).is_password? given_password
  end

  private def set_password_changed_at
    self.password_changed_at = Time.now if password_changed?
  end
end
