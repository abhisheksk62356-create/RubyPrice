class TrackedProduct < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :product_group, optional: true

  validates :product_id, uniqueness: { scope: :user_id }
  validates :target_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :monitoring_on, -> { where(monitoring_enabled: true) }
  scope :monitoring_off, -> { where(monitoring_enabled: false) }

  def target_reached?
    return false if target_price.blank? || product.current_price.blank?

    product.current_price <= target_price
  end
end
