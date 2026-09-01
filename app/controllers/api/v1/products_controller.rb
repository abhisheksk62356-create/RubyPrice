module Api
  module V1
    class ProductsController < Api::BaseController
      before_action :set_tracked_product, only: %i[show update destroy refresh]

      def index
        tracked_products = current_user.tracked_products.includes(:product).page(params[:page]).per(20)

        render json: {
          products: tracked_products.map { |tp| serialize(tp) },
          page: tracked_products.current_page,
          total_pages: tracked_products.total_pages,
          total_count: tracked_products.total_count
        }
      end

      def show
        render json: serialize(@tracked_product)
      end

      def create
        result = ProductUrlIntake.call(user: current_user, raw_url: params[:url])

        if result.success?
          render json: serialize(result.tracked_product), status: :created
        else
          render_error(:unprocessable_content, result.error_code.to_s.upcase, result.error_message)
        end
      end

      def update
        if @tracked_product.update(tracked_product_params)
          render json: serialize(@tracked_product)
        else
          render_error(:unprocessable_content, "VALIDATION_FAILED", @tracked_product.errors.full_messages.to_sentence)
        end
      end

      def destroy
        @tracked_product.destroy
        head :no_content
      end

      def refresh
        PriceRefreshJob.perform_later(@tracked_product.product_id)
        render json: { status: "queued" }, status: :accepted
      end

      private

      def set_tracked_product
        @tracked_product = current_user.tracked_products.find_by!(product_id: params[:id])
      end

      def tracked_product_params
        params.permit(:target_price, :monitoring_enabled)
      end

      def serialize(tracked_product)
        product = tracked_product.product

        {
          id: product.id,
          name: product.name,
          domain: product.domain,
          url: product.url,
          image_url: product.image_url,
          current_price: product.current_price,
          previous_price: product.previous_price,
          currency: product.currency,
          availability: product.availability,
          price_change_amount: product.price_change_amount,
          price_change_percent: product.price_change_percent,
          last_checked_at: product.last_checked_at,
          target_price: tracked_product.target_price,
          monitoring_enabled: tracked_product.monitoring_enabled
        }
      end
    end
  end
end
