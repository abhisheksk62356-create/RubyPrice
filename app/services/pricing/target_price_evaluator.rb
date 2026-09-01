module Pricing
  # After a product's price is refreshed, checks every user tracking it with
  # a target price and creates/triggers a PriceAlert for anyone whose target
  # has now been reached.
  class TargetPriceEvaluator
    def self.call(product) = new(product).call

    def initialize(product)
      @product = product
    end

    def call
      return [] if @product.current_price.blank?

      @product.tracked_products.where.not(target_price: nil).filter_map do |tracked_product|
        next unless tracked_product.target_reached?

        find_or_trigger_alert(tracked_product)
      end
    end

    private

    def find_or_trigger_alert(tracked_product)
      alert = PriceAlert.find_or_initialize_by(user: tracked_product.user, product: @product)
      alert.target_price = tracked_product.target_price

      return nil if alert.persisted? && alert.status == "triggered"

      alert.save! if alert.new_record?
      alert.trigger!(@product.current_price)
      alert
    end
  end
end
