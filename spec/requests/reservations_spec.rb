require "rails_helper"

RSpec.describe "予約", type: :request do
  let!(:event) do
    Event.create!(
      title: "梅酒づくりワークショップ",
      venue: "うめ公民館",
      starts_at: Time.zone.local(2026, 11, 15, 10, 0),
      capacity: 20,
      price: 1500
    )
  end

  describe "POST /events/:event_id/reservations" do
    it "予約を作成して、イベントの詳細画面へ戻る" do
      params = { reservation: { name: "初花", email: "hatsuka@example.com", quantity: 2 } }

      expect { post event_reservations_path(event), params: params }
        .to change(Reservation, :count).by(1)

      expect(response).to redirect_to(event_path(event))
      follow_redirect!
      expect(response.body).to include("予約しました。")
      expect(response.body).to include("残り 18席")
    end
  end
end
