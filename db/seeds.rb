# Development/demo seed data for RubyPrice. NOT representative of real
# production usage — every record here is clearly synthetic.
#
# Run with: bin/rails db:seed

unless Rails.env.development?
  abort("Seeds are intended for the development environment only.")
end

puts "Seeding demo data…"

demo_user = User.find_or_create_by!(email: "demo@rubyprice.example.com") do |user|
  user.password = "demo-password-123"
  user.password_confirmation = "demo-password-123"
end

admin_user = User.find_or_create_by!(email: "admin@rubyprice.example.com") do |user|
  user.password = "admin-password-123"
  user.password_confirmation = "admin-password-123"
  user.role = "admin"
end

demo_products = [
  {
    name: "Wireless Over-Ear Headphones (Demo)",
    domain: "demo-electronics.example.com",
    starting_price: 99.99,
    currency: "EUR",
    trend: :down
  },
  {
    name: "Adjustable Standing Desk (Demo)",
    domain: "demo-furniture.example.com",
    starting_price: 349.00,
    currency: "USD",
    trend: :up
  },
  {
    name: "Mechanical Keyboard (Demo)",
    domain: "demo-peripherals.example.com",
    starting_price: 129.00,
    currency: "EUR",
    trend: :down
  },
  {
    name: "4K Monitor 27-inch (Demo)",
    domain: "demo-electronics.example.com",
    starting_price: 279.99,
    currency: "EUR",
    trend: :flat
  }
]

demo_products.each_with_index do |attrs, index|
  slug = attrs[:name].parameterize
  canonical_url = "https://#{attrs[:domain]}/products/#{slug}"

  product = Product.find_or_create_by!(canonical_url: canonical_url) do |p|
    p.name = attrs[:name]
    p.url = canonical_url
    p.domain = attrs[:domain]
    p.currency = attrs[:currency]
    p.availability = "in_stock"
    p.monitoring_enabled = true
  end

  # Build a small price history trending up, down, or flat over two weeks.
  price = BigDecimal(attrs[:starting_price].to_s)
  14.downto(0) do |days_ago|
    delta = case attrs[:trend]
    when :down then -(rand(0..150) / 100.0)
    when :up then (rand(0..150) / 100.0)
    else (rand(-40..40) / 100.0)
    end
    price = [ price + BigDecimal(delta.to_s), BigDecimal("5.00") ].max
    product.record_price!(price.round(2), currency: attrs[:currency], checked_at: days_ago.days.ago)
  end

  product.crawl_runs.find_or_create_by!(url: canonical_url, status: "succeeded") do |run|
    run.http_status = 200
    run.response_time_ms = rand(120..900)
    run.started_at = 1.hour.ago
    run.completed_at = 1.hour.ago + 0.4.seconds
  end

  # Half the demo products get a target price just above the current price
  # (so the alert has already triggered, for demo purposes); the rest get
  # one below it (so the alert is still pending).
  tracked = TrackedProduct.find_or_create_by!(user: demo_user, product: product) do |tp|
    multiplier = index.even? ? 1.05 : 0.85
    tp.target_price = (product.current_price * multiplier).round(2)
  end

  Pricing::TargetPriceEvaluator.call(product) if tracked.target_price.present?
end

puts "Seeded #{User.count} users, #{Product.count} products, #{PriceHistory.count} price points, #{CrawlRun.count} crawl runs, #{PriceAlert.count} alerts."
puts "Demo login: demo@rubyprice.example.com / demo-password-123"
puts "Admin login: admin@rubyprice.example.com / admin-password-123"
