require "domain_helper"

RSpec.describe EmailAddress do
  it "前後の空白を取り、小文字にそろえる" do
    expect(EmailAddress.new(" Hatsuka@Example.COM ").value).to eq("hatsuka@example.com")
  end

  it "そろえたあとの値が同じなら、同じメールアドレス" do
    expect(EmailAddress.new("Hatsuka@example.com")).to eq(EmailAddress.new("hatsuka@example.com"))
  end

  it "形が正しくなければ作れない" do
    expect { EmailAddress.new("hatsuka.example.com") }
      .to raise_error(ArgumentError, "メールアドレスの形が正しくありません: \"hatsuka.example.com\"")
  end
end
