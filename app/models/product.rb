class Product < ApplicationRecord
  AVAILABILITIES = %w[in_stock out_of_stock unknown].freeze

  has_many :tracked_products, dependent: :destroy
  has_many :users, through: :tracked_products
  has_many :price_histories, -> { order(checked_at: :asc) }, dependent: :destroy
  has_many :crawl_runs, dependent: :destroy
  has_many :price_alerts, dependent: :destroy

  validates :name, presence: true
  validates :url, presence: true
  validates :canonical_url, presence: true, uniqueness: true
  validates :domain, presence: true
  validates :currency, presence: true, length: { is: 3 }
  validates :availability, inclusion: { in: AVAILABILITIES }
  validates :current_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :monitored, -> { where(monitoring_enabled: true) }
  scope :search_by_name, ->(query) { where("products.name ILIKE :q OR products.domain ILIKE :q", q: "%#{sanitize_sql_like(query)}%") if query.present? }
  scope :newest_first, -> { order(created_at: :desc) }
  scope :lowest_price_first, -> { order(Arel.sql("current_price ASC NULLS LAST")) }
  scope :largest_drop_first, -> { order(Arel.sql("(previous_price - current_price) DESC NULLS LAST")) }

  def price_change_amount
    return nil if current_price.nil? || previous_price.nil?

    current_price - previous_price
  end

  def price_change_percent
    return nil if current_price.nil? || previous_price.nil? || previous_price.zero?

    ((current_price - previous_price) / previous_price * 100).round(2)
  end

  def price_drop?
    change = price_change_amount
    change.present? && change.negative?
  end

  def lowest_recorded_price
    price_histories.minimum(:price) || current_price
  end

  def highest_recorded_price
    price_histories.maximum(:price) || current_price
  end

  def first_recorded_price
    price_histories.order(:checked_at).first&.price || current_price
  end

  def record_price!(amount, currency: self.currency, checked_at: Time.current)
    transaction do
      price_histories.create!(price: amount, currency: currency, checked_at: checked_at)

      update!(
        previous_price: current_price,
        current_price: amount,
        currency: currency,
        last_checked_at: checked_at
      )
    end
  end
end
