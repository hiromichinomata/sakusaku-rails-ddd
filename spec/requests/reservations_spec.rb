require "rails_helper"

RSpec.describe "予約", type: :request do
  let(:event) { create(:event, capacity: 20) }

  def reserve(quantity:, name: "初花", email: "hatsuka@example.com")
    post event_reservations_path(event),
         params: { reservation: { name: name, email: email, quantity: quantity } }
  end

  describe "POST /events/:event_id/reservations" do
    it "仮予約を作成して、お支払いのお願いをメールで送る" do
      perform_enqueued_jobs do
        expect { reserve(quantity: 2) }.to change(Reservation, :count).by(1)
      end

      expect(delivered_subjects).to eq([ "【うめチケット】お支払いのお願い：梅酒づくりワークショップ" ])

      reservation = Reservation.last
      expect(reservation).to be_pending
      expect(response).to redirect_to(reservation_path(reservation))
      follow_redirect!
      expect(response.body).to include("仮予約しました。15分以内にお支払いください。")
    end

    it "無料のイベントは、その場で予約が確定して、確定のメールを送る" do
      event.update!(price: 0)

      perform_enqueued_jobs { reserve(quantity: 2) }

      expect(Reservation.last).to be_confirmed
      expect(delivered_subjects).to eq([ "【うめチケット】予約が確定しました：梅酒づくりワークショップ" ])
    end

    it "入力に誤りがあれば、予約せずにエラーを表示する" do
      expect { reserve(name: "", email: "hatsuka.example.com", quantity: 0) }
        .not_to change(Reservation, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("お名前を入力してください")
      expect(response.body).to include("メールアドレスは不正な値です")
      expect(response.body).to include("人数は0より大きい値にしてください")
    end

    it "1回の予約は4人まで" do
      expect { reserve(quantity: 5) }.not_to change(Reservation, :count)

      expect(response.body).to include("人数は4以下の値にしてください")
    end

    it "同じメールアドレスで、同じイベントを二重に予約できない" do
      create(:reservation, event: event, email: "hatsuka@example.com")

      expect { reserve(quantity: 1, email: "hatsuka@example.com") }
        .not_to change(Reservation, :count)

      expect(response.body).to include("メールアドレスでは、すでに予約があります")
    end

    it "キャンセルした予約があっても、もう一度予約できる" do
      create(:reservation, event: event, email: "hatsuka@example.com", status: "canceled")

      expect { reserve(quantity: 1, email: "hatsuka@example.com") }
        .to change(Reservation, :count).by(1)
    end

    it "開始時刻を過ぎたイベントは予約できない" do
      event.update!(starts_at: 1.hour.ago)

      expect { reserve(quantity: 1) }.not_to change(Reservation, :count)

      expect(response.body).to include("このイベントの受付は終了しました")
    end

    context "残りの席が2席のとき" do
      # 席の数は残席（ticket_inventories）が持っている
      before { event.ticket_inventory.update!(reserved_count: 18) }

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
