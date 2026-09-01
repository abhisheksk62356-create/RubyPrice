FactoryBot.define do
  factory :product_group do
    user
    sequence(:name) { |n| "Comparison #{n}" }
  end
end
