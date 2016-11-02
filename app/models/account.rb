class Account < ApplicationRecord
  validates :name, presence: true
  validates :password, presence: true

  scope :named, ->(name) { where(name: name) }
  scope :unconfirmed, ->{ where(confirmed_at: nil) }
  scope :confirmed, ->{ where.not(confirmed_at: nil) }

  # finds and deletes any unconfirmed accounts with the given name
  # returns true if this has happened, otherwise false.
  def self.reclaim(name)
    !Account.unconfirmed.named(name).delete_all.zero?
  end

  def confirm
    update(confirmed_at: Time.zone.now)
  end

  def confirmed?
    confirmed_at?
  end
end
