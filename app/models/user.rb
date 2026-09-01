class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token

  has_many :sessions, dependent: :destroy
  has_many :tracked_products, dependent: :destroy
  has_many :products, through: :tracked_products
  has_many :price_alerts, dependent: :destroy
  has_many :product_groups, dependent: :destroy

  ROLES = %w[member admin].freeze

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true,
                     uniqueness: { case_sensitive: false },
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :role, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end
end
