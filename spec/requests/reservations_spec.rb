require "rails_helper"

RSpec.describe "予約", type: :request do
  let(:event) { create(:event, capacity: 20) }

  def reserve(quantity:, name: "初花", email: "hatsuka@example.com")
    post event_reservations_path(event),
         params: { reservation: { name: name, email: email, quantity: quantity } }
  end

  describe "POST /events/:event_id/reservations" do
    it "予約を作成して、イベントの詳細画面へ戻る" do
      expect { reserve(quantity: 2) }.to change(Reservation, :count).by(1)

      expect(response).to redirect_to(event_path(event))
      follow_redirect!
      expect(response.body).to include("予約しました。")
      expect(response.body).to include("残り 18席")
    end

    it "入力に誤りがあれば、予約せずにエラーを表示する" do
      expect { reserve(name: "", email: "hatsuka.example.com", quantity: 0) }
        .not_to change(Reservation, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("お名前を入力してください")
      expect(response.body).to include("メールアドレスは不正な値です")
      expect(response.body).to include("人数は0より大きい値にしてください")
    end

    context "残りの席が2席のとき" do
      before { create(:reservation, event: event, quantity: 18) }

      it "2人なら予約できる" do
        expect { reserve(quantity: 2) }.to change(Reservation, :count).by(1)
      end

      it "3人は予約できない" do
        expect { reserve(quantity: 3) }.not_to change(Reservation, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("人数が残りの席数（2席）を超えています")
      end
    end
  end
end
