require "rails_helper"

RSpec.describe Crawler::UrlValidator do
  describe ".call" do
    context "with a valid public URL" do
      it "accepts a normal https product URL" do
        result = described_class.call("https://shop.example.com/products/1")

        expect(result.valid?).to be true
        expect(result.uri.host).to eq("shop.example.com")
      end

      it "downcases the host and strips the fragment" do
        result = described_class.call("https://Shop.Example.COM/products/1#reviews")

        expect(result.uri.host).to eq("shop.example.com")
        expect(result.uri.fragment).to be_nil
      end
    end

    context "with blank or malformed input" do
      it "rejects a blank URL" do
        expect(described_class.call("").valid?).to be false
        expect(described_class.call("   ").valid?).to be false
      end

      it "rejects unparseable input" do
        result = described_class.call("http://[not a valid host")
        expect(result.valid?).to be false
        expect(result.error_code).to eq(:invalid_url)
      end

      it "rejects a URL with no host" do
        result = described_class.call("https:///path")
        expect(result.valid?).to be false
      end
    end

    context "with unsafe schemes" do
      %w[file:///etc/passwd ftp://example.com/file javascript:alert(1) data:text/html,hi].each do |url|
        it "rejects #{url}" do
          result = described_class.call(url)
          expect(result.valid?).to be false
          expect(result.error_code).to eq(:unsupported_scheme)
        end
      end
    end

    context "with localhost and loopback addresses" do
      %w[
        http://localhost/
        http://127.0.0.1/
        http://127.0.0.1:3000/admin
        http://0.0.0.0/
        http://[::1]/
      ].each do |url|
        it "rejects #{url}" do
          result = described_class.call(url)
          expect(result.valid?).to be false
          expect(result.error_code).to be_in(%i[blocked_host blocked_ip])
        end
      end
    end

    context "with private network ranges" do
      %w[
        http://10.0.0.5/
        http://172.16.0.5/
        http://192.168.1.5/
        http://169.254.1.1/
      ].each do |url|
        it "rejects #{url}" do
          result = described_class.call(url)
          expect(result.valid?).to be false
          expect(result.error_code).to eq(:blocked_ip)
        end
      end
    end

    context "with cloud metadata endpoints" do
      it "rejects the AWS/GCP/Azure metadata address" do
        result = described_class.call("http://169.254.169.254/latest/meta-data/")
        expect(result.valid?).to be false
        expect(result.error_code).to eq(:blocked_ip)
      end
    end

    context "with internal-looking hostnames" do
      %w[http://myhost.internal/ http://printer.local/ http://db.corp/].each do |url|
        it "rejects #{url}" do
          result = described_class.call(url)
          expect(result.valid?).to be false
          expect(result.error_code).to eq(:blocked_host)
        end
      end
    end

    context "when DNS resolves to a private address (DNS rebinding style attack)" do
      it "rejects the request" do
        allow(Resolv).to receive(:getaddresses).with("evil.example.com").and_return([ "127.0.0.1" ])

        result = described_class.call("http://evil.example.com/")

        expect(result.valid?).to be false
        expect(result.error_code).to eq(:blocked_ip)
      end
    end

    context "when DNS resolution fails" do
      it "returns a dns_resolution_failed error" do
        allow(Resolv).to receive(:getaddresses).with("doesnotexist.invalid").and_return([])

        result = described_class.call("http://doesnotexist.invalid/")

        expect(result.valid?).to be false
        expect(result.error_code).to eq(:dns_resolution_failed)
      end
    end
  end
end
