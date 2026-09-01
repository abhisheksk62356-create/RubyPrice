require "rails_helper"

RSpec.describe CrawlRun, type: :model do
  it { is_expected.to belong_to(:product).optional }
  it { is_expected.to validate_presence_of(:url) }

  describe "#mark_running!, #mark_succeeded!, #mark_failed!" do
    it "transitions through a successful run" do
      crawl_run = create(:crawl_run, status: "pending")

      crawl_run.mark_running!
      expect(crawl_run.status).to eq("running")
      expect(crawl_run.started_at).to be_present

      crawl_run.mark_succeeded!(http_status: 200, response_time_ms: 350)
      expect(crawl_run.status).to eq("succeeded")
      expect(crawl_run.http_status).to eq(200)
      expect(crawl_run.completed_at).to be_present
    end

    it "records failure details" do
      crawl_run = create(:crawl_run, status: "pending")

      crawl_run.mark_failed!(error_code: :timeout, error_message: "took too long")

      expect(crawl_run.status).to eq("failed")
      expect(crawl_run.error_code).to eq("timeout")
      expect(crawl_run.error_message).to eq("took too long")
    end
  end
end
