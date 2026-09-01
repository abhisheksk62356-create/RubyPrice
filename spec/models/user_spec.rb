require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it { is_expected.to have_secure_password }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to have_many(:tracked_products) }
  it { is_expected.to have_many(:products).through(:tracked_products) }
  it { is_expected.to have_many(:sessions).dependent(:destroy) }

  it "is valid with valid attributes" do
    expect(user).to be_valid
  end

  it "downcases and strips the email" do
    user.email = "  Test@Example.COM  "
    user.valid?
    expect(user.email).to eq("test@example.com")
  end

  it "rejects duplicate emails case-insensitively" do
    create(:user, email: "duplicate@example.com")
    duplicate = build(:user, email: "Duplicate@Example.com")

    expect(duplicate).not_to be_valid
  end

  it "rejects passwords shorter than 8 characters" do
    user.password = "short"
    user.password_confirmation = "short"

    expect(user).not_to be_valid
  end

  it "never stores the plaintext password" do
    user.save!
    expect(user.attributes.values).not_to include("correct-horse-battery")
    expect(user.password_digest).not_to eq("correct-horse-battery")
  end

  it "generates a unique api_token on creation" do
    user.save!
    expect(user.api_token).to be_present
  end

  describe "#admin?" do
    it "is true for admin role" do
      expect(build(:user, :admin).admin?).to be true
    end

    it "is false for member role" do
      expect(user.admin?).to be false
    end
  end
end
