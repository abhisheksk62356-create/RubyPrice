FactoryBot.define do
  factory :crawl_run do
    product
    url { product&.canonical_url || "https://shop.example.com/products/1" }
    status { "pending" }
  end
end
