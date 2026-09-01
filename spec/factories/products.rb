FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Wireless Headphones #{n}" }
    sequence(:url) { |n| "https://shop.example.com/products/#{n}" }
    canonical_url { url }
    domain { "shop.example.com" }
    current_price { 79.99 }
    previous_price { 99.99 }
    currency { "EUR" }
    availability { "in_stock" }
    monitoring_enabled { true }
    last_checked_at { Time.current }
  end
end
