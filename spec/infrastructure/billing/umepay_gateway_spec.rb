require "rails_helper"

RSpec.describe Billing::UmepayGateway do
  let(:gateway) { described_class.new(api_key: "sk_test") }
  let(:charges_url) { "https://api.umepay.example/v1/charges" }
  let(:refunds_url) { "https://api.umepay.example/v1/refunds" }

  def charge
    gateway.charge(amount: Money.new(3000), token: "tok_visa", idempotency_key: "charge-reservation-1-tok_visa")
  end

  it "支払いを頼み、うめペイの支払いIDを返す" do
    stub_request(:post, charges_url)
      .with(body: { amount: 3000, currency: "jpy", source: "tok_visa" }.to_json,
            headers: { "Authorization" => "Bearer sk_test", "Idempotency-Key" => "charge-reservation-1-tok_visa" })
      .to_return(status: 200, body: { id: "ch_umepay_1" }.to_json)

    expect(charge).to eq("ch_umepay_1")
  end

  it "402 が返ったら、カードが使えなかった" do
    stub_request(:post, charges_url).to_return(status: 402, body: { error: "card_declined" }.to_json)

    expect { charge }.to raise_error(Billing::CardDeclined, "カードが利用できませんでした")
  end

  it "500 が返ったら、決済サービスにつながらなかった" do
    stub_request(:post, charges_url).to_return(status: 500)

    expect { charge }.to raise_error(Billing::GatewayUnavailable, "うめペイが 500 を返しました")
  end

  it "タイムアウトしたら、決済サービスにつながらなかった" do
    stub_request(:post, charges_url).to_timeout

    expect { charge }.to raise_error(Billing::GatewayUnavailable, "うめペイにつながりませんでした（Net::OpenTimeout）")
  end

  it "タイムアウトのあとのやり直しでも、同じ冪等キーを送る" do
    stub_request(:post, refunds_url).to_timeout.then.to_return(status: 200, body: { id: "re_umepay_1" }.to_json)
    refund = -> { gateway.refund(charge_id: "ch_umepay_1", amount: Money.new(3000), idempotency_key: "refund-reservation-1") }

    expect { refund.call }.to raise_error(Billing::GatewayUnavailable)
    expect(refund.call).to eq("re_umepay_1")

    expect(a_request(:post, refunds_url).with(headers: { "Idempotency-Key" => "refund-reservation-1" }))
      .to have_been_made.twice
  end
end
