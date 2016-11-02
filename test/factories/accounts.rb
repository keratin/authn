FactoryGirl.define do
  factory :account do
    sequence :name do |n|
      "name-#{n}"
    end

    transient do
      clear_password 'secret'
    end

    password{ BCrypt::Password.create(clear_password) }

    trait :confirmed do
      confirmed_at{ Time.zone.now }
    end

    trait :unconfirmed do
      confirmed_at nil
    end
  end
end
