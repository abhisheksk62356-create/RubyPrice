FactoryBot.define do
  factory :price_alert do
    user
    product
    target_price { 49.99 }
    status { "pending" }
  end
end
