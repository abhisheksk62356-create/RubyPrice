# Adds/removes one of the current user's own tracked products to/from a
# comparison group they own. Both lookups are scoped to current_user, so a
# user can only ever link or unlink their own tracked products and groups.
class ProductGroupMembershipsController < ApplicationController
  before_action :set_product_group

  def create
    tracked_product = current_user.tracked_products.find(params[:tracked_product_id])
    tracked_product.update(product_group: @product_group)

    redirect_to product_group_path(@product_group), notice: "Added to comparison."
  end

  def destroy
    tracked_product = @product_group.tracked_products.find(params[:id])
    tracked_product.update(product_group: nil)

    redirect_to product_group_path(@product_group), notice: "Removed from comparison."
  end

  private

  def set_product_group
    @product_group = current_user.product_groups.find(params[:product_group_id])
  end
end
