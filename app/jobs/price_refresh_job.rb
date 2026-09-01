# Manually or scheduler-triggered refresh of a single, already-tracked
# product. Creates a fresh CrawlRun each time so CrawlRun history/admin
# stats reflect every attempt.
class PriceRefreshJob < ApplicationJob
  queue_as :extraction

  retry_on Faraday::TimeoutError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(product_id)
    product = Product.find_by(id: product_id)
    return if product.nil?

    crawl_run = product.crawl_runs.create!(url: product.canonical_url, status: "pending")
    ProductExtractionPipeline.call(crawl_run)
  end
end
