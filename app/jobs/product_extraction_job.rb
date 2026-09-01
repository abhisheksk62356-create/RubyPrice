# Runs the extraction pipeline for a freshly created CrawlRun (queued right
# after a user submits a new product URL). Idempotent: re-running it for the
# same crawl_run simply re-fetches and re-persists the current state.
class ProductExtractionJob < ApplicationJob
  queue_as :extraction

  retry_on Faraday::TimeoutError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(crawl_run_id)
    crawl_run = CrawlRun.find_by(id: crawl_run_id)
    return if crawl_run.nil? || crawl_run.product.nil?

    ProductExtractionPipeline.call(crawl_run)
  end
end
