# Lets a user manually tag several of their own tracked products (e.g. the
# same item's listing on Amazon, Temu, and AliExpress) as "the same product"
# so the app can show them side by side and highlight the cheapest one.
#
# RubyPrice never searches other marketplaces on its own — every listing in
# a group is a URL the user explicitly added and RubyPrice validated/crawled
# individually, same as any other tracked product.
class ProductGroup < ApplicationRecord
  belongs_to :user
  has_many :tracked_products, dependent: :nullify
  has_many :products, through: :tracked_products

  validates :name, presence: true

  # The tracked_product with the lowest current known price in the group,
  # ignoring listings that don't have a price yet. Only meaningful to
  # highlight as "the" cheapest when every priced listing shares a currency
  # — see #mixed_currencies?.
  def cheapest_tracked_product
    priced_tracked_products.order("products.current_price ASC").first
  end

  # True once two or more differently-currencied listings have a price, at
  # which point a single "cheapest" badge would be misleading without
  # currency conversion.
  def mixed_currencies?
    priced_tracked_products.map { |tp| tp.product.currency }.uniq.size > 1
  end

  private

  def priced_tracked_products
    tracked_products.joins(:product).where.not(products: { current_price: nil })
  end
end
