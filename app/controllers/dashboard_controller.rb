class DashboardController < ApplicationController
  def show
    @tracked_products = current_user.tracked_products.includes(:product)
    @products = current_user.products

    @stats = {
      tracked_products: @tracked_products.count,
      price_drops: @products.where("previous_price IS NOT NULL AND current_price < previous_price").count,
      price_checks: CrawlRun.where(product_id: @products.select(:id)).succeeded.count,
      lowest_price: @products.minimum(:current_price)
    }

    @recent_products = @products.order(updated_at: :desc).limit(6)
  end
end
