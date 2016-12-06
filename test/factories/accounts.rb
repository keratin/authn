FactoryGirl.define do
  factory :account do
    sequence :username do |n|
      "name-#{n}"
    end

    transient do
      clear_password 'secret'
    end

    password{ BCrypt::Password.create(clear_password) }

    trait :archived do
      username nil
      password nil
      deleted_at{ Time.zone.now }
    end

    trait :locked do
      locked true
    end
  end
end
