# 決済の窓口（アダプター）が守る約束。偽物と本物の両方に、同じ例を流す。
# 使う側で、gateway・valid_token・declined_token と、外の返事を用意する prepare_success を定義する。
RSpec.shared_examples "決済の窓口の約束" do
  it "支払いが通ったら、支払いIDの文字列を返す" do
    prepare_success

    charge_id = gateway.charge(amount: Money.new(3000), token: valid_token, idempotency_key: "contract-charge")

    expect(charge_id).to be_a(String).and(be_present)
  end

  it "カードが使えなければ、Billing::CardDeclined を投げる" do
    expect { gateway.charge(amount: Money.new(3000), token: declined_token, idempotency_key: "contract-declined") }
      .to raise_error(Billing::CardDeclined)
  end

  it "返金が通ったら、返金IDの文字列を返す" do
    prepare_success

    refund_id = gateway.refund(charge_id: "ch_contract", amount: Money.new(3000), idempotency_key: "contract-refund")

    expect(refund_id).to be_a(String).and(be_present)
  end

  it "金額は Money で受け取る（整数は受け取らない）" do
    prepare_success

    expect { gateway.charge(amount: 3000, token: valid_token, idempotency_key: "contract-integer") }
      .to raise_error(NoMethodError)
  end
end
