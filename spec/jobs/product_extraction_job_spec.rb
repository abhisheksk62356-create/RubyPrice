require "rails_helper"

RSpec.describe ProductExtractionJob, type: :job do
  it "runs the extraction pipeline for the crawl run's product" do
    product = create(:product, current_price: nil)
    crawl_run = create(:crawl_run, product: product, url: product.canonical_url)

    stub_request(:get, product.canonical_url)
      .to_return(status: 200, body: Rails.root.join("spec/fixtures/product_json_ld.html").read)

    described_class.perform_now(crawl_run.id)

    crawl_run.reload
    product.reload

    expect(crawl_run.status).to eq("succeeded")
    expect(product.current_price).to eq(BigDecimal("79.99"))
  end

  it "records a failed crawl run when the fetch fails" do
    product = create(:product)
    crawl_run = create(:crawl_run, product: product, url: product.canonical_url)

    stub_request(:get, product.canonical_url).to_timeout

    described_class.perform_now(crawl_run.id)

    expect(crawl_run.reload.status).to eq("failed")
  end

  it "does nothing for a crawl run that no longer exists" do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end

  it "is idempotent: running it twice just re-fetches and re-persists" do
    product = create(:product, current_price: nil)
    crawl_run = create(:crawl_run, product: product, url: product.canonical_url)

    stub_request(:get, product.canonical_url)
      .to_return(status: 200, body: Rails.root.join("spec/fixtures/product_json_ld.html").read)

    2.times { described_class.perform_now(crawl_run.id) }

    expect(product.reload.current_price).to eq(BigDecimal("79.99"))
  end
end
