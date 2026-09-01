require "rails_helper"

RSpec.describe Crawler::RobotsChecker do
  subject(:checker) { described_class.new(user_agent: "RubyPriceBot/1.0") }

  def uri_for(path)
    URI.parse("https://shop.example.com#{path}")
  end

  it "allows everything when robots.txt is missing (404)" do
    stub_request(:get, "https://shop.example.com/robots.txt").to_return(status: 404)

    expect(checker.allowed?(uri_for("/products/1"))).to be true
  end

  it "disallows a path blocked for our user agent specifically" do
    stub_request(:get, "https://shop.example.com/robots.txt").to_return(status: 200, body: <<~ROBOTS)
      User-agent: RubyPriceBot
      Disallow: /admin/
    ROBOTS

    expect(checker.allowed?(uri_for("/admin/settings"))).to be false
    expect(checker.allowed?(uri_for("/products/1"))).to be true
  end

  it "falls back to the wildcard group when there is no dedicated group" do
    stub_request(:get, "https://shop.example.com/robots.txt").to_return(status: 200, body: <<~ROBOTS)
      User-agent: *
      Disallow: /private/
    ROBOTS

    expect(checker.allowed?(uri_for("/private/data"))).to be false
    expect(checker.allowed?(uri_for("/products/1"))).to be true
  end

  it "lets a more specific Allow override a broader Disallow" do
    stub_request(:get, "https://shop.example.com/robots.txt").to_return(status: 200, body: <<~ROBOTS)
      User-agent: *
      Disallow: /products/
      Allow: /products/public/
    ROBOTS

    expect(checker.allowed?(uri_for("/products/public/1"))).to be true
    expect(checker.allowed?(uri_for("/products/private/1"))).to be false
  end

  it "caches the parsed robots.txt so it is only fetched once per host" do
    stub = stub_request(:get, "https://shop.example.com/robots.txt").to_return(status: 200, body: "User-agent: *\nDisallow: /admin/")

    2.times { checker.allowed?(uri_for("/products/1")) }

    expect(stub).to have_been_requested.once
  end
end
