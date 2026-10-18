require "domain_helper"

RSpec.describe Ticketing::Applicant do
  it "名前とメールアドレスを持つ。メールアドレスは EmailAddress にする" do
    applicant = described_class.new(name: " 初花 ", email: "Hatsuka@example.com")

    expect(applicant.name).to eq("初花")
    expect(applicant.email).to eq(EmailAddress.new("hatsuka@example.com"))
  end

  it "名前が空なら作れない" do
    expect { described_class.new(name: " ", email: "hatsuka@example.com") }
      .to raise_error(ArgumentError, "申込者の名前を指定してください")
  end
end
