class ProductGroupsController < ApplicationController
  before_action :set_product_group, only: %i[show destroy]

  def index
    @product_groups = current_user.product_groups.includes(tracked_products: :product)
  end

  def new
    @product_group = current_user.product_groups.new
    @preselected_tracked_product_id = params[:tracked_product_id]
  end

  def create
    @product_group = current_user.product_groups.new(product_group_params)

    if @product_group.save
      if params[:tracked_product_id].present?
        tracked_product = current_user.tracked_products.find_by(id: params[:tracked_product_id])
        tracked_product&.update(product_group: @product_group)
      end

      redirect_to product_group_path(@product_group), notice: "Comparison group created."
    else
      @preselected_tracked_product_id = params[:tracked_product_id]
      render :new, status: :unprocessable_content
    end
  end

  def show
    @ungrouped_tracked_products = current_user.tracked_products.where(product_group_id: nil).includes(:product)
  end

  def destroy
    @product_group.destroy
    redirect_to product_groups_path, notice: "Comparison group deleted."
  end

  private

  def set_product_group
    @product_group = current_user.product_groups.find(params[:id])
  end

  def product_group_params
    params.require(:product_group).permit(:name)
  end
end
