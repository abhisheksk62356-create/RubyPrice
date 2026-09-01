require "rails_helper"

RSpec.describe Crawler::HttpClient do
  subject(:client) { described_class.new(open_timeout: 1, timeout: 1, max_bytes: 1_000_000) }

  describe "#get" do
    it "returns the body on a plain 200 response" do
      stub_request(:get, "https://shop.example.com/1").to_return(status: 200, body: "<html>hi</html>")

      result = client.get(URI.parse("https://shop.example.com/1"))

      expect(result.success?).to be true
      expect(result.body).to eq("<html>hi</html>")
    end

    it "follows a safe redirect to another public host" do
      stub_request(:get, "https://shop.example.com/1").to_return(status: 302, headers: { "Location" => "https://shop.example.com/final" })
      stub_request(:get, "https://shop.example.com/final").to_return(status: 200, body: "final page")

      result = client.get(URI.parse("https://shop.example.com/1"))

      expect(result.success?).to be true
      expect(result.final_url).to eq("https://shop.example.com/final")
    end

    it "refuses to follow a redirect into a private/internal address (SSRF via redirect)" do
      stub_request(:get, "https://shop.example.com/1").to_return(status: 302, headers: { "Location" => "http://169.254.169.254/latest/meta-data/" })

      result = client.get(URI.parse("https://shop.example.com/1"))

      expect(result.success?).to be false
      expect(result.error_code).to eq(:blocked_ip)
    end

    it "gives up after too many redirects" do
      stub_request(:get, "https://shop.example.com/1").to_return(status: 302, headers: { "Location" => "https://shop.example.com/2" })
      stub_request(:get, "https://shop.example.com/2").to_return(status: 302, headers: { "Location" => "https://shop.example.com/3" })
      stub_request(:get, "https://shop.example.com/3").to_return(status: 302, headers: { "Location" => "https://shop.example.com/4" })
      stub_request(:get, "https://shop.example.com/4").to_return(status: 302, headers: { "Location" => "https://shop.example.com/5" })

      result = client.get(URI.parse("https://shop.example.com/1"))

      expect(result.success?).to be false
    end

    it "truncates a response larger than the configured max size" do
      small_client = described_class.new(open_timeout: 1, timeout: 1, max_bytes: 10)
      stub_request(:get, "https://shop.example.com/1").to_return(status: 200, body: "0123456789extra-bytes-here")

      result = small_client.get(URI.parse("https://shop.example.com/1"))

      expect(result.body.bytesize).to eq(10)
    end

    it "reports a non-200 status as a failure" do
      stub_request(:get, "https://shop.example.com/1").to_return(status: 404)

      result = client.get(URI.parse("https://shop.example.com/1"))

      expect(result.success?).to be false
      expect(result.error_code).to eq(:bad_status)
    end

    it "reports a timeout as a failure" do
      stub_request(:get, "https://shop.example.com/1").to_timeout

      result = client.get(URI.parse("https://shop.example.com/1"))

      expect(result.success?).to be false
      expect(result.error_code).to eq(:timeout)
    end
  end
end
