module Api
  module V1
    class ProductHistoryController < Api::BaseController
      def index
        tracked_product = current_user.tracked_products.find_by!(product_id: params[:product_id])
        history = tracked_product.product.price_histories.order(:checked_at)

        render json: {
          product_id: tracked_product.product_id,
          history: history.map { |entry| { price: entry.price, currency: entry.currency, checked_at: entry.checked_at } }
        }
      end
    end
  end
end
