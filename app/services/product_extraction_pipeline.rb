# The full extraction pipeline used by both the initial "Analyze Product"
# flow and manual/scheduled refreshes:
#
#   CrawlRun -> Crawler::PageFetcher -> ProductExtraction::ExtractorRegistry
#     -> Product/PriceHistory persistence -> Pricing::TargetPriceEvaluator
#
# Takes a CrawlRun (already created, referencing the Product to update) and
# drives it to completion, recording success/failure on the CrawlRun itself
# so the UI and admin dashboard have full visibility into what happened.
class ProductExtractionPipeline
  def self.call(crawl_run) = new(crawl_run).call

  def initialize(crawl_run, page_fetcher: Crawler::PageFetcher.new)
    @crawl_run = crawl_run
    @product = crawl_run.product
    @page_fetcher = page_fetcher
  end

  def call
    @crawl_run.mark_running!
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    outcome = @page_fetcher.fetch(@crawl_run.url)
    elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round

    if outcome.success?
      handle_success(outcome, elapsed_ms)
    else
      @crawl_run.mark_failed!(error_code: outcome.error_code, error_message: outcome.error_message, http_status: outcome.http_status)
    end

    @crawl_run
  end

  private

  def handle_success(outcome, elapsed_ms)
    extracted = ProductExtraction::ExtractorRegistry.extract(outcome.body, outcome.final_url)

    persist_product(extracted)

    @crawl_run.mark_succeeded!(http_status: outcome.http_status, response_time_ms: elapsed_ms)
  end

  def persist_product(extracted)
    ActiveRecord::Base.transaction do
      @product.name = extracted.name if extracted.name.present?
      @product.image_url = extracted.image_url if extracted.image_url.present?
      @product.availability = extracted.availability if extracted.availability.present?
      @product.save!

      @product.record_price!(extracted.price_amount, currency: extracted.currency || @product.currency) if extracted.price_amount.present?
    end

    Pricing::TargetPriceEvaluator.call(@product) if extracted.price_amount.present?
  end
end
