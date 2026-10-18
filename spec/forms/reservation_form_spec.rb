require "rails_helper"

RSpec.describe ReservationForm do
  it "入力の形が正しければ、ユースケースの引数にできる" do
    form = described_class.new(name: "初花", email: "hatsuka@example.com", quantity: "2")

    expect(form).to be_valid
    expect(form.to_h).to eq(name: "初花", email: "hatsuka@example.com", count: 2)
  end

  it "入力の形の誤りを、項目ごとのメッセージにする" do
    form = described_class.new(name: "", email: "hatsuka.example.com", quantity: "5")

    expect(form).not_to be_valid
    expect(form.errors.full_messages).to eq(
      [ "お名前を入力してください", "メールアドレスは不正な値です", "人数は4以下の値にしてください" ]
    )
  end

  it "業務のルールの誤りも、フォームのメッセージとして表せる" do
    form = described_class.new(name: "初花", email: "hatsuka@example.com", quantity: 3)

    form.add_business_error(Ticketing::Inventory::NotEnoughSeats.new(2))

    expect(form.errors.full_messages).to eq([ "人数が残りの席数（2席）を超えています" ])
  end
end
