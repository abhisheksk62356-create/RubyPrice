class Rack::Attack
  # Rack::Attack stores its counters in Rails.cache, which is Redis-backed
  # (see config/environments), so throttling is shared across all app
  # instances rather than being per-process.
  Rack::Attack.cache.store = Rails.cache

  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  throttle("product_analysis/ip", limit: 15, period: 5.minutes) do |req|
    req.ip if req.path == "/products" && req.post?
  end

  throttle("login/ip", limit: 10, period: 3.minutes) do |req|
    req.ip if req.path == "/login" && req.post?
  end

  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    headers = { "Retry-After" => retry_after.to_s }

    if request.path.start_with?("/api/")
      body = { error: { code: "RATE_LIMITED", message: "Too many requests. Please slow down." } }.to_json
      [ 429, headers.merge("Content-Type" => "application/json"), [ body ] ]
    else
      body = File.read(Rails.root.join("public/429.html"))
      [ 429, headers.merge("Content-Type" => "text/html"), [ body ] ]
    end
  end
end
