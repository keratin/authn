FactoryGirl.define do
  factory :account do
    sequence :name do |n|
      "name-#{n}"
    end

    transient do
      clear_password 'secret'
    end

    password{ BCrypt::Password.create(clear_password) }
  end
end
