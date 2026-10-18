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

    it "入力に誤りがあれば、予約せずにエラーを表示する" do
      params = { reservation: { name: "", email: "hatsuka.example.com", quantity: 0 } }

      expect { post event_reservations_path(event), params: params }
        .not_to change(Reservation, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("お名前を入力してください")
      expect(response.body).to include("メールアドレスは不正な値です")
      expect(response.body).to include("人数は0より大きい値にしてください")
    end

    context "残りの席が2席のとき" do
      before do
        event.reservations.create!(name: "先客", email: "first@example.com", quantity: 18)
      end

      it "2人なら予約できる" do
        params = { reservation: { name: "初花", email: "hatsuka@example.com", quantity: 2 } }

        expect { post event_reservations_path(event), params: params }
          .to change(Reservation, :count).by(1)
      end

      it "3人は予約できない" do
        params = { reservation: { name: "初花", email: "hatsuka@example.com", quantity: 3 } }

        expect { post event_reservations_path(event), params: params }
          .not_to change(Reservation, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("人数が残りの席数（2席）を超えています")
      end
    end
  end
end
