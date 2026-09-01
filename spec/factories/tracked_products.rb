FactoryBot.define do
  factory :tracked_product do
    user
    product
    monitoring_enabled { true }
    target_price { nil }
  end
end
