# Periodically enqueues a PriceRefreshJob for every monitored product whose
# price hasn't been checked recently, then reschedules itself. Sidekiq's
# Redis-backed scheduled set survives deploys/restarts, so this self-chaining
# approach needs no extra cron infrastructure.
#
# Kick it off once (e.g. from an initializer or a deploy hook) with:
#   ScheduledPriceCheckJob.perform_later
class ScheduledPriceCheckJob < ApplicationJob
  queue_as :scheduling

  CHECK_INTERVAL = 6.hours
  RESCHEDULE_EVERY = 15.minutes
  BATCH_SIZE = 200

  def perform
    due_products.find_each(batch_size: BATCH_SIZE) do |product|
      PriceRefreshJob.perform_later(product.id)
    end
  ensure
    self.class.set(wait: RESCHEDULE_EVERY).perform_later
  end

  private

  def due_products
    Product.monitored.where(
      "last_checked_at IS NULL OR last_checked_at < ?", CHECK_INTERVAL.ago
    )
  end
end
