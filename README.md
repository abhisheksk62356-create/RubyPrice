# RubyPrice

**Track prices. Spot better deals.**

A production-oriented Ruby/Rails price monitoring and web data extraction
platform. Users submit permitted public product URLs; a Ruby backend
validates the URL, fetches the page, parses structured and HTML data with
Nokogiri, normalizes pricing, and tracks price history over time — with
extraction and monitoring running asynchronously via Sidekiq and Redis.

## Overview

RubyPrice lets a user register, add a public product URL, and have the app
automatically extract the product's name, price, currency, image, and
availability. From there they can monitor the price on a schedule, set a
target price, see the full price history, and get notified when the target
is reached — all from a Rails-native (Hotwire/Turbo + Tailwind) dashboard, or
via the documented REST API.

## Features

- Automated product data extraction (JSON-LD → OpenGraph → HTML fallbacks)
- Decimal-safe, currency-aware price parsing (`€49.99`, `49,99 €`, `$1,234.56`, …)
- Scheduled + on-demand price monitoring via Sidekiq/Redis
- Full price history with a lightweight, dependency-free SVG chart
- Per-user target prices and price-drop alerts
- Searchable, filterable, sortable, paginated product dashboard
- REST API with token authentication
- SSRF-hardened crawler with robots.txt compliance and per-domain rate limiting
- Hashed passwords, rate-limited logins, CSRF protection, per-user authorization
- Admin dashboard for crawl/error observability
- RSpec test suite covering models, services, requests, jobs, and security

## Technology Stack

- **Backend:** Ruby 3.4, Rails 8.1, PostgreSQL, Redis, Sidekiq
- **Extraction:** Nokogiri, Faraday
- **Frontend:** ERB, Hotwire (Turbo + Stimulus), Tailwind CSS (no React/SPA)
- **Testing/Quality:** RSpec, FactoryBot, WebMock, Shoulda Matchers, RuboCop, Brakeman, bundler-audit
- **Ops:** Docker, Docker Compose, GitHub Actions

## Architecture

See [`docs/architecture.md`](docs/architecture.md) for the full request/job
diagram, data model, and scaling notes.

## Data Extraction Pipeline

```text
URL -> Crawler::UrlValidator (SSRF checks) -> Crawler::RobotsChecker
     -> Crawler::CrawlerPolicy (rate limit) -> Crawler::HttpClient
     -> Nokogiri -> ProductExtraction::ExtractorRegistry
          (JSON-LD -> OpenGraph/meta -> CSS selectors)
     -> ProductExtraction::PriceExtractor (currency-aware, BigDecimal)
     -> Product / PriceHistory persisted -> Pricing::TargetPriceEvaluator
```

## Security

- **Authentication:** `has_secure_password` (bcrypt), database-backed
  sessions with signed, httponly cookies.
- **Authorization:** users can only ever access their own tracked products —
  enforced by scoping every lookup through `current_user.tracked_products`.
- **CSRF:** Rails' built-in protection on all non-API forms.
- **Rate limiting:** Rails 8's `rate_limit` on login/product-analysis;
  `Rack::Attack` on the whole API and login path.
- **Secrets:** loaded from environment variables (`.env`, never committed);
  see [`.env.example`](.env.example).

### SSRF Protection

`Crawler::UrlValidator` (`app/services/crawler/url_validator.rb`) rejects:

- non-`http(s)` schemes (`file://`, `ftp://`, `javascript:`, `data:`, …)
- `localhost`, loopback, and `*.internal`/`*.local`/`*.lan`/`*.corp` hostnames
- private/reserved IPv4 and IPv6 ranges (RFC1918, link-local, etc.)
- known cloud metadata addresses (`169.254.169.254`, …)
- every DNS-resolved address for a hostname, not just the literal host

`Crawler::HttpClient` re-runs this validation on **every redirect hop**, so a
public URL that redirects to an internal address is still blocked. See
`spec/services/crawler/url_validator_spec.rb` and
`spec/services/crawler/http_client_spec.rb` for the full test coverage.

### Crawler Ethics

- Respects each site's `robots.txt` (`Crawler::RobotsChecker`), failing open
  only when `robots.txt` itself is missing.
- Rate-limits itself per domain (`Crawler::CrawlerPolicy`).
- Identifies itself with a clear `User-Agent` (`CRAWLER_USER_AGENT`).
- Never attempts to bypass logins, paywalls, CAPTCHAs, or anti-bot measures.

## Local Setup

### Requirements

- Ruby 3.4+
- PostgreSQL 14+
- Redis 6+ (needed for the modern `redis-client`/Sidekiq RESP3 handshake)

### Install

```bash
bundle install
cp .env.example .env   # then fill in real local values
bin/rails db:setup     # create, migrate, and seed the database
```

### Environment Variables

See [`.env.example`](.env.example). Never commit `.env`.

### Database Setup

```bash
bin/rails db:create db:migrate db:seed
```

Seeded demo accounts (development only):

- `demo@rubyprice.example.com` / `demo-password-123`
- `admin@rubyprice.example.com` / `admin-password-123` (admin role)

### Running Rails

```bash
bin/dev   # Puma + Tailwind watcher, via Procfile.dev
```

### Running Sidekiq

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

> **Windows notes:**
> - If you see `MSYS2 could not be found` during `bundle install`, run
>   `ridk install` (choose option 3) once to add the MinGW toolchain, then retry.
> - If your checkout path contains non-ASCII characters (e.g. an em dash), run
>   `chcp 65001` in your shell first and set `DISABLE_BOOTSNAP=1`, since
>   Bootsnap's native path cache can't handle non-ASCII paths on Windows —
>   see `config/boot.rb`.
> - The bundled `tailwindcss-ruby` binary (Bun-based) has a Windows bug where
>   `bin/rails tailwindcss:build` fails with `EEXIST` if `app/assets/builds`
>   already exists. If that happens, delete the directory
>   (`rm -rf app/assets/builds`) and rebuild.

## Docker

```bash
cp .env.example .env   # fill in RAILS_MASTER_KEY at minimum
docker compose up --build
```

This starts `postgres`, `redis`, `web` (Puma, on http://localhost:3000), and
`worker` (Sidekiq), each with health checks. See [`docker-compose.yml`](docker-compose.yml).

## Testing

```bash
bin/rails db:test:prepare
bundle exec rspec
```

Tests are organized by type under `spec/` (`models`, `services`, `requests`,
`jobs`) and use FactoryBot factories plus deterministic HTML fixtures in
`spec/fixtures/` — no test depends on a real external website.

```bash
bin/rubocop        # style
bin/brakeman        # static security analysis
bin/bundler-audit   # known-CVE gem audit
```

## API

Full reference: [`docs/api.md`](docs/api.md).

```bash
curl -H "Authorization: Bearer $API_TOKEN" https://your-domain.example.com/api/v1/products
```

## Scaling Strategy

Architected for growth toward **10,000+ users** on a single well-organized
Rails monolith: paginated queries, N+1-safe `includes`/`joins`, all
extraction/monitoring work offloaded to Sidekiq, a shared Redis cache, and a
stateless web tier that can be scaled horizontally by running more `web` and
`worker` containers behind a load balancer. See
[`docs/architecture.md`](docs/architecture.md#scalability) for detail — no
Kubernetes, Kafka, or microservices, since none of that is warranted at this
scale.

## Performance

No synthetic load-test numbers are published here — see
[`docs/architecture.md`](docs/architecture.md) for the load-bearing design
decisions (background jobs, indexes, pagination, caching) that make the app
suitable for load testing rather than a specific claimed benchmark.

## Future Improvements

- Email notifications for triggered price alerts (once a mailer is fully configured)
- Browser extension for one-click "track this page"
- Multi-currency conversion for cross-store price comparison
- Per-store custom CSS-selector overrides for stubborn pages

## Screenshots

_Add screenshots of the landing page, dashboard, and product detail view here._

## License

[MIT](LICENSE)
