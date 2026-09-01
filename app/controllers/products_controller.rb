class ProductsController < ApplicationController
  rate_limit to: 20, within: 5.minutes, only: %i[create refresh], with: -> { redirect_to products_path, alert: "You're doing that too often. Please wait a moment." }

  before_action :set_tracked_product, only: %i[show update destroy refresh]

  def index
    scope = current_user.tracked_products.includes(:product)
    scope = apply_search(scope)
    scope = apply_filter(scope)
    scope = apply_sort(scope)

    @tracked_products = scope.page(params[:page]).per(12)
  end

  def new
    @raw_url = params[:url]
  end

  def create
    result = ProductUrlIntake.call(user: current_user, raw_url: params[:url])

    if result.success?
      redirect_to product_path(result.product), notice: "Analyzing product… this usually takes a few seconds."
    else
      flash.now[:alert] = result.error_message
      @raw_url = params[:url]
      render :new, status: :unprocessable_content
    end
  end

  def show
    @product = @tracked_product.product
    @price_history = @product.price_histories.order(:checked_at)
    @latest_crawl_run = @product.crawl_runs.recent.first
  end

  def update
    if @tracked_product.update(tracked_product_params)
      redirect_to product_path(@tracked_product.product), notice: "Tracking preferences updated."
    else
      redirect_to product_path(@tracked_product.product), alert: @tracked_product.errors.full_messages.to_sentence
    end
  end

  def refresh
    PriceRefreshJob.perform_later(@tracked_product.product_id)
    redirect_to product_path(@tracked_product.product), notice: "Refreshing price…"
  end

  def destroy
    @tracked_product.destroy
    redirect_to products_path, notice: "Product removed from your tracked list."
  end

  private

  def set_tracked_product
    @tracked_product = current_user.tracked_products.find_by!(product_id: params[:id])
  end

  def tracked_product_params
    params.require(:tracked_product).permit(:target_price, :monitoring_enabled)
  end

  def apply_search(scope)
    return scope if params[:q].blank?

    scope.joins(:product).merge(Product.search_by_name(params[:q]))
  end

  def apply_filter(scope)
    case params[:monitoring]
    when "on" then scope.monitoring_on
    when "off" then scope.monitoring_off
    else scope
    end
  end

  def apply_sort(scope)
    scope = scope.joins(:product)

    case params[:sort]
    when "lowest_price" then scope.merge(Product.lowest_price_first)
    when "largest_drop" then scope.merge(Product.largest_drop_first)
    else scope.merge(Product.newest_first)
    end
  end
end
