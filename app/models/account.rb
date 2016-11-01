class Account < ApplicationRecord
  validates :name, presence: true
  validates :password, presence: true

  scope :unconfirmed, ->{ where(confirmed_at: nil) }
  scope :confirmed, ->{ where.not(confirmed_at: nil) }

  def confirm
    update(confirmed_at: Time.zone.now)
  end

  def confirmed?
    confirmed_at?
  end
end
