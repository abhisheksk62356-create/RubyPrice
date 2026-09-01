class PriceAlert < ApplicationRecord
  STATUSES = %w[pending triggered dismissed].freeze

  belongs_to :user
  belongs_to :product

  validates :target_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :triggered, -> { where(status: "triggered") }

  def trigger!(price)
    update!(status: "triggered", triggered_price: price, triggered_at: Time.current)
  end
end
