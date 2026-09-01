module Admin
  class DashboardController < BaseController
    def show
      @stats = {
        total_users: User.count,
        total_products: Product.count,
        total_crawl_runs: CrawlRun.count,
        successful_crawl_runs: CrawlRun.succeeded.count,
        failed_crawl_runs: CrawlRun.failed.count,
        average_crawl_duration_ms: CrawlRun.succeeded.average(:response_time_ms)&.round
      }

      @recent_errors = CrawlRun.failed.recent.limit(20)
    end
  end
end
