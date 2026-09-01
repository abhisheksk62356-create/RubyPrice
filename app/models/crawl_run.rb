class CrawlRun < ApplicationRecord
  STATUSES = %w[pending running succeeded failed].freeze

  belongs_to :product, optional: true

  validates :url, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
  scope :failed, -> { where(status: "failed") }
  scope :succeeded, -> { where(status: "succeeded") }

  def duration_ms
    return response_time_ms if response_time_ms.present?
    return nil unless started_at && completed_at

    ((completed_at - started_at) * 1000).round
  end

  def mark_running!
    update!(status: "running", started_at: Time.current)
  end

  def mark_succeeded!(http_status:, response_time_ms: nil)
    update!(
      status: "succeeded",
      http_status: http_status,
      response_time_ms: response_time_ms || duration_ms,
      completed_at: Time.current
    )
  end

  def mark_failed!(error_code:, error_message:, http_status: nil)
    update!(
      status: "failed",
      http_status: http_status,
      error_code: error_code,
      error_message: error_message.to_s.truncate(2000),
      completed_at: Time.current
    )
  end
end
