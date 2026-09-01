# Trims old operational data (CrawlRun history, stale PriceHistory points for
# products no one tracks any more) so the database doesn't grow unbounded.
# Self-reschedules daily, same pattern as ScheduledPriceCheckJob.
class CleanupJob < ApplicationJob
  queue_as :scheduling

  CRAWL_RUN_RETENTION = 90.days
  RESCHEDULE_EVERY = 1.day
  DELETE_BATCH_SIZE = 1000

  def perform
    CrawlRun.where("created_at < ?", CRAWL_RUN_RETENTION.ago).in_batches(of: DELETE_BATCH_SIZE).delete_all
    delete_untracked_products_history
  ensure
    self.class.set(wait: RESCHEDULE_EVERY).perform_later
  end

  private

  def delete_untracked_products_history
    Product.left_joins(:tracked_products)
           .where(tracked_products: { id: nil })
           .where(monitoring_enabled: false)
           .find_each(batch_size: 200, &:destroy)
  end
end
