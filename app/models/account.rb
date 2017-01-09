class Account < ApplicationRecord
  USERNAME_MIN_LENGTH = 3

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

  def sessions
    @sessions ||= RefreshToken.sessions(id)
  end

  private def set_password_changed_at
    self.password_changed_at = Time.now if password_changed?
  end

  module UsernameValidations
    def self.included(base)
      base.validates :username, presence: { message: ErrorCodes::MISSING }
      base.validate  :username_format
      base.validate  :username_domain
    end

    # worried about an imperfect regex? see: http://www.regular-expressions.info/email.html
    #
    # SECURITY NOTE: if someone can flood the system with usernames in excess of a megabyte, they
    # might be able to ddoss a bad regex. in my simple tests, a similar regex without character limits
    # could take up to 1000ms on a 100_000_000 character username. adding character limits brings that
    # time down to around 50ms.
    EMAIL = /\A[A-Z0-9._%+-]{1,64}@(?:[A-Z0-9-]{1,63}\.){1,125}[A-Z]{2,63}\z/i

    private def username_format
      return if username.blank?

      if Rails.application.config.email_usernames
        errors.add(:username, ErrorCodes::FORMAT_INVALID) unless username =~ EMAIL
      elsif username.length < Account::USERNAME_MIN_LENGTH
        errors.add(:username, ErrorCodes::FORMAT_INVALID)
      end
    end

    private def username_domain
      return if username.blank?
      return unless Rails.application.config.email_usernames && Rails.application.config.email_username_domains

      unless username.split('@').last.in?(Rails.application.config.email_username_domains)
        errors.add(:username, ErrorCodes::FORMAT_INVALID)
      end
    end
  end

  module PasswordValidations
    def self.included(base)
      base.validates :password, presence: { message: ErrorCodes::MISSING }
      base.validate  :password_strength
    end

    private def password_strength
      if password.present? && PasswordScorer.new(password).perform < Rails.application.config.minimum_password_score
        errors.add(:password, ErrorCodes::INSECURE)
      end
    end
  end
end
