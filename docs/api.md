# REST API

Base URL: `https://your-domain.example.com/api/v1`

## Authentication

Every endpoint requires an `Authorization: Bearer <api_token>` header. Each
user has a unique `api_token`, visible on their [Settings](/settings) page.

```bash
curl -H "Authorization: Bearer $API_TOKEN" https://your-domain.example.com/api/v1/products
```

A missing or invalid token returns `401 Unauthorized`.

## Rate limits

All `/api/*` requests are throttled to **60 requests per minute per IP**
(`Rack::Attack`, see `config/initializers/rack_attack.rb`). Exceeding the
limit returns `429 Too Many Requests` with a `Retry-After` header.

## Errors

Errors are always returned as JSON in this shape:

```json
{
  "error": {
    "code": "INVALID_URL",
    "message": "Please provide a valid product URL."
  }
}
```

| HTTP status | Meaning |
|---|---|
| 401 | Missing/invalid API token |
| 404 | Record not found, or not owned by the authenticated user |
| 422 | Validation failed (invalid URL, SSRF-blocked URL, bad params) |
| 429 | Rate limit exceeded |

## Endpoints

### `GET /api/v1/products`

List the authenticated user's tracked products.

Query params: `page` (default 1).

```json
{
  "products": [
    {
      "id": 1,
      "name": "Wireless Headphones",
      "domain": "shop.example.com",
      "url": "https://shop.example.com/products/1",
      "image_url": "https://shop.example.com/images/headphones.jpg",
      "current_price": "79.99",
      "previous_price": "99.99",
      "currency": "EUR",
      "availability": "in_stock",
      "price_change_amount": "-20.00",
      "price_change_percent": -20.0,
      "last_checked_at": "2026-08-30T10:00:00Z",
      "target_price": "69.99",
      "monitoring_enabled": true
    }
  ],
  "page": 1,
  "total_pages": 1,
  "total_count": 1
}
```

### `GET /api/v1/products/:id`

Return a single tracked product (by `Product` id). 404 if the current user
isn't tracking it.

### `POST /api/v1/products`

Add a new product URL.

Params: `url` (required).

```bash
curl -X POST https://your-domain.example.com/api/v1/products \
  -H "Authorization: Bearer $API_TOKEN" \
  -d "url=https://shop.example.com/products/1"
```

Returns `201 Created` with the tracked product on success, `422` with a
structured error (e.g. `code: "BLOCKED_IP"`) if the URL fails SSRF/URL
validation. Extraction runs asynchronously via Sidekiq after this returns —
poll `GET /api/v1/products/:id` for the extracted name/price.

### `PATCH /api/v1/products/:id`

Update tracking preferences.

Params: `target_price`, `monitoring_enabled`.

### `DELETE /api/v1/products/:id`

Stop tracking a product for the current user. Returns `204 No Content`.

### `POST /api/v1/products/:id/refresh`

Queue an immediate price refresh. Returns `202 Accepted` with
`{"status": "queued"}`; the price updates asynchronously.

### `GET /api/v1/products/:id/history`

Full price history for a tracked product.

```json
{
  "product_id": 1,
  "history": [
    { "price": "99.99", "currency": "EUR", "checked_at": "2026-08-20T09:00:00Z" },
    { "price": "79.99", "currency": "EUR", "checked_at": "2026-08-30T09:00:00Z" }
  ]
}
```
