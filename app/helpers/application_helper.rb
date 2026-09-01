module ApplicationHelper
  CURRENCY_SYMBOLS = {
    "EUR" => "€", "USD" => "$", "GBP" => "£", "JPY" => "¥",
    "CHF" => "CHF", "CAD" => "$", "AUD" => "$", "INR" => "₹"
  }.freeze

  def currency_symbol(code)
    CURRENCY_SYMBOLS.fetch(code.to_s.upcase, code.to_s)
  end

  def price_change_badge_class(product)
    product.price_drop? ? "badge-green" : "badge-red"
  end
end
