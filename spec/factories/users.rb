FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "correct-horse-battery" }
    password_confirmation { "correct-horse-battery" }
    role { "member" }

    trait :admin do
      role { "admin" }
    end
  end
end
