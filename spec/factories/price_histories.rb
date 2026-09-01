FactoryBot.define do
  factory :price_history do
    product
    price { 79.99 }
    currency { "EUR" }
    checked_at { Time.current }
  end
end
