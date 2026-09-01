class PriceHistory < ApplicationRecord
  belongs_to :product

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { is: 3 }
  validates :checked_at, presence: true
end
