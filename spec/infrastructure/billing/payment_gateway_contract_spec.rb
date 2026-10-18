require "rails_helper"

RSpec.describe "決済の窓口の契約" do
  describe Billing::FakePaymentGateway do
    let(:gateway) { described_class.new }
    let(:valid_token) { "tok_visa" }
    let(:declined_token) { "tok_declined" }

    def prepare_success; end

    include_examples "決済の窓口の約束"
  end

  describe Billing::UmepayGateway do
    let(:gateway) { described_class.new(api_key: "sk_test") }
    let(:valid_token) { "tok_umepay_ok" }
    let(:declined_token) { "tok_umepay_ng" }

    before do
      stub_request(:post, "https://api.umepay.example/v1/charges")
        .with(body: hash_including("source" => declined_token))
        .to_return(status: 402, body: { error: "card_declined" }.to_json)
    end

    def prepare_success
      stub_request(:post, "https://api.umepay.example/v1/charges")
        .with(body: hash_including("source" => valid_token)).to_return(status: 200, body: { id: "ch_umepay_1" }.to_json)
      stub_request(:post, "https://api.umepay.example/v1/refunds").to_return(status: 200, body: { id: "re_umepay_1" }.to_json)
    end

    include_examples "決済の窓口の約束"
  end
end
