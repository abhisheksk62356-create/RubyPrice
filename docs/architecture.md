# Architecture

RubyPrice is a Ruby on Rails monolith split into a request path and a
background-processing path, sharing one PostgreSQL database.

## Request path

```text
Browser
   |
   v
Rails router
   |
   v
Controllers (ApplicationController, ProductsController, Api::V1::*, Admin::*)
   |
   v
Service objects (ProductUrlIntake, Pricing::TargetPriceEvaluator, ...)
   |
   v
PostgreSQL (via Active Record)
```

Controllers stay thin: they authenticate the request, authorize the current
user against the record being accessed, delegate to a service object, and
render. Business logic — URL validation, extraction, pricing — lives in
`app/services`, not in controllers or models.

## Background processing path

```text
User submits a URL
   |
   v
ProductUrlIntake creates Product + TrackedProduct + CrawlRun
   |
   v
ProductExtractionJob.perform_later  ---->  Sidekiq  ---->  Redis (queue)
                                              |
                                              v
                                       ProductExtractionPipeline
                                              |
                              +---------------+----------------+
                              v                                v
                     Crawler::PageFetcher              (on success)
                              |                                |
                              v                                v
                  Nokogiri via ExtractorRegistry     Product/PriceHistory saved
                              |                                |
                              +----------------+----------------+
                                               v
                                  Pricing::TargetPriceEvaluator
                                               |
                                               v
                                          PriceAlert
```

`ScheduledPriceCheckJob` and `CleanupJob` are self-rescheduling Sidekiq jobs
(each re-enqueues itself with `perform_in` when it finishes) so periodic
price checks and data retention don't require a separate cron daemon.

## Why background jobs

Fetching a third-party page and parsing it is inherently slow and
unreliable — the request could hang for seconds, or the target site could be
down. None of that should block a web request or tie up a Puma thread, so
every crawl happens in a `ProductExtractionJob` / `PriceRefreshJob`, and the
web response only ever has to create a few rows and enqueue a job.

## Data model

- **User** — has_secure_password, has_many :tracked_products, has_many
  :products (through tracked_products).
- **Product** — one row per unique `canonical_url`, shared across every user
  tracking it. Holds the latest known price/availability plus denormalized
  `current_price`/`previous_price` for fast list rendering.
- **TrackedProduct** — the join between a user and a product; carries the
  per-user `target_price` and `monitoring_enabled` flag, so two users can
  track the same product with different targets.
- **PriceHistory** — one row per price observation, ordered by `checked_at`.
- **CrawlRun** — one row per fetch attempt (success or failure), with
  timing and error detail, feeding the admin dashboard.
- **PriceAlert** — created/triggered by `Pricing::TargetPriceEvaluator` when
  a tracked product's price reaches a user's target.

## Security

- **SSRF protection** — `Crawler::UrlValidator` rejects unsafe schemes,
  localhost/loopback, private IPv4/IPv6 ranges, and known cloud metadata
  addresses, both for the literal host and for every DNS-resolved address.
  `Crawler::HttpClient` re-validates on every redirect hop rather than
  trusting the initial check.
- **Authorization** — every product-scoped controller action looks up the
  record through `current_user.tracked_products`, so a user can never load,
  refresh, or delete another user's tracked product (returns 404, not 403,
  to avoid confirming the record's existence).
- **Rate limiting** — Rails' built-in `rate_limit` throttles login and
  product-analysis endpoints per IP; `Rack::Attack` adds a second layer for
  the whole `/api/` namespace and `/login`, backed by the same Redis cache
  store so limits are shared across app instances.
- **Crawler ethics** — `Crawler::RobotsChecker` fetches and respects each
  site's `robots.txt` before crawling, `Crawler::CrawlerPolicy` caps requests
  per domain per minute, and the User-Agent identifies the bot so site owners
  can block it if they choose.

## Scalability

- Pagination (Kaminari) everywhere a list could grow unbounded.
- `includes`/`joins` used wherever an index page renders associated records,
  to avoid N+1 queries.
- Redis-backed cache store shared by Rails.cache, Rack::Attack, and Sidekiq.
- Stateless web tier — sessions are looked up from a database-backed
  `Session` row via a signed cookie, so any web process can serve any
  request.

This is a single well-organized Rails monolith, not a microservice
architecture — for the traffic RubyPrice is designed for (up to roughly
10,000 users), a monolith with background jobs and a cache is simpler to
operate and reason about than a distributed system, while still scaling
horizontally by adding more `web`/`worker` containers.
