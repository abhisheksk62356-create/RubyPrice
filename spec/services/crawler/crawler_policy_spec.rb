require "rails_helper"

RSpec.describe Crawler::CrawlerPolicy do
  subject(:policy) { described_class.new("shop.example.com") }

  it "allows requests under the per-minute limit" do
    5.times { policy.record_request! }
    expect(policy.allowed?).to be true
  end

  it "blocks requests once the per-minute limit is reached" do
    described_class::MAX_REQUESTS_PER_DOMAIN_PER_MINUTE.times { policy.record_request! }
    expect(policy.allowed?).to be false
  end

  it "tracks each domain independently" do
    described_class::MAX_REQUESTS_PER_DOMAIN_PER_MINUTE.times { policy.record_request! }

    other_policy = described_class.new("other-shop.example.com")
    expect(other_policy.allowed?).to be true
  end
end
