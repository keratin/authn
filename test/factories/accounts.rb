FactoryGirl.define do
  factory :account do
    sequence :name do |n|
      "name-#{n}"
    end

    password{ BCrypt::Password.create('secret') }

    trait :confirmed do
      confirmed_at{ Time.zone.now }
    end
  end
end
