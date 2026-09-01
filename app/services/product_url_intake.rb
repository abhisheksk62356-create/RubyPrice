# Handles a user submitting a new product URL: validates it (SSRF-safe),
# finds or creates the shared Product row, links it to the submitting user
# via a TrackedProduct, and queues the background extraction job. This is
# the single entry point the "Add Product" page and the API both call.
class ProductUrlIntake
  Result = Struct.new(:success?, :product, :tracked_product, :crawl_run, :error_code, :error_message, keyword_init: true)

  def self.call(user:, raw_url:) = new(user: user, raw_url: raw_url).call

  def initialize(user:, raw_url:)
    @user = user
    @raw_url = raw_url
  end

  def call
    validation = Crawler::UrlValidator.call(@raw_url)
    return failure(validation.error_code, validation.error_message) unless validation.valid?

    uri = validation.uri

    ActiveRecord::Base.transaction do
      product = find_or_initialize_product(uri)
      product.save! if product.new_record?

      tracked_product = @user.tracked_products.find_or_create_by!(product: product)

      crawl_run = product.crawl_runs.create!(url: uri.to_s, status: "pending")

      ProductExtractionJob.perform_later(crawl_run.id)

      Result.new(success?: true, product: product, tracked_product: tracked_product, crawl_run: crawl_run)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(:invalid_product, e.message)
  end

  private

  def find_or_initialize_product(uri)
    Product.find_by(canonical_url: uri.to_s) || Product.new(
      name: uri.host,
      url: uri.to_s,
      canonical_url: uri.to_s,
      domain: uri.host,
      currency: "EUR",
      availability: "unknown"
    )
  end

  def failure(code, message)
    Result.new(success?: false, error_code: code, error_message: message)
  end
end
