require "rails_helper"

RSpec.describe "予約の API", type: :request do
  let(:event) { create(:event, capacity: 4, price: 1500) }

  def reserve(event_id: event.id, quantity: 2, email: "hatsuka@example.com", name: "初花")
    post api_event_reservations_path(event_id),
         params: { reservation: { name: name, email: email, quantity: quantity } }, as: :json
  end

  it "申し込めたら 201 と予約を返す" do
    reserve

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["reservation"]).to include("status" => "pending", "total_price" => 3000)
  end

  it "入力の形が誤っていれば 422 と項目ごとのエラーを返す" do
    reserve(name: "", quantity: 5)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to eq(
      "name" => [ "お名前を入力してください" ], "quantity" => [ "人数は4以下の値にしてください" ]
    )
  end

  it "残席が足りなければ 409 とエラーコードを返す" do
    event.ticket_inventory.update!(reserved_count: 3)

    reserve(quantity: 2)

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body["error"]).to eq(
      "code" => "not_enough_seats", "message" => "残りの席数（1席）を超えています"
    )
  end

  it "二重予約なら 409 を返す" do
    reserve(quantity: 1)
    reserve(quantity: 1)

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig("error", "code")).to eq("already_reserved")
  end

  describe "Idempotency-Key" do
    def reserve_with_key(key, email: "hatsuka@example.com")
      post api_event_reservations_path(event),
           params: { reservation: { name: "初花", email: email, quantity: 2 } },
           headers: { "Idempotency-Key" => key }, as: :json
    end

    it "同じキーで送り直しても、申込は1回だけで、同じ応答が返る" do
      reserve_with_key("key-1")
      first = response.parsed_body

      reserve_with_key("key-1")

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq(first)
      expect(Reservation.count).to eq(1)
    end

    it "違うキーなら、別の申込として扱う（同じメールアドレスなら二重予約）" do
      reserve_with_key("key-1")
      reserve_with_key("key-2")

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("already_reserved")
    end

    it "業務のエラーになった申込は、同じキーでもう一度やり直せる" do
      event.ticket_inventory.update!(reserved_count: 4)
      reserve_with_key("key-1")
      expect(response).to have_http_status(:conflict)

      event.ticket_inventory.update!(reserved_count: 0) # キャンセルが出て、席が空いた
      reserve_with_key("key-1")

      expect(response).to have_http_status(:created)
    end
  end

  it "イベントがなければ 404 を返す" do
    reserve(event_id: 0)

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("not_found")
  end
end
