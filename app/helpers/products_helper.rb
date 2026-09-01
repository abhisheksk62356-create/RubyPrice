module ProductsHelper
  # Builds the SVG polyline points for a simple, dependency-free price
  # history line chart (viewBox 0 0 600 200).
  def price_history_chart_points(history, width: 600, height: 200, padding: 12)
    return "" if history.size < 2

    prices = history.map { |h| h.price.to_f }
    min, max = prices.minmax
    range = (max - min).zero? ? 1.0 : (max - min)

    usable_width = width - (padding * 2)
    usable_height = height - (padding * 2)
    step = usable_width / (prices.size - 1).to_f

    prices.each_with_index.map do |price, index|
      x = padding + (index * step)
      y = padding + usable_height - ((price - min) / range * usable_height)
      "#{x.round(1)},#{y.round(1)}"
    end.join(" ")
  end
end
