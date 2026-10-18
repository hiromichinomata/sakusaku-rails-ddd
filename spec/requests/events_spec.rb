require "rails_helper"

RSpec.describe "イベント", type: :request do
  describe "GET /events" do
    it "イベントのタイトルを一覧に表示する" do
      create(:event, title: "梅酒づくりワークショップ")

      get events_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("梅酒づくりワークショップ")
    end
  end

  describe "GET /events/:id" do
    it "イベントの詳細を表示する" do
      event = create(:event, venue: "うめ公民館", starts_at: Time.zone.local(2026, 11, 15, 10, 0),
                             capacity: 20, price: 1500)

      get event_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("うめ公民館")
      expect(response.body).to include("2026年11月15日 10:00")
      expect(response.body).to include("定員 20人（残り 20席）")
      expect(response.body).to include("1,500円")
    end
  end

  describe "GET /events/:id の残りの席" do
    it "キャンセルされた予約の席は、残りの席に戻る" do
      event = create(:event, capacity: 20)
      create(:reservation, event: event, quantity: 4, status: "canceled")

      get event_path(event)

      expect(response.body).to include("残り 20席")
    end
  end

  describe "POST /events" do
    let(:valid_params) do
      { event: attributes_for(:event, title: "梅林ガイドツアー", starts_at: "2026-12-06 13:00") }
    end

    it "イベントを登録して、詳細画面へ移動する" do
      expect { post events_path, params: valid_params }.to change(Event, :count).by(1)

      expect(response).to redirect_to(event_path(Event.last))
    end

    it "入力に誤りがあれば、登録せずにエラーを表示する" do
      invalid_params = { event: valid_params[:event].merge(title: "", capacity: 0) }

      expect { post events_path, params: invalid_params }.not_to change(Event, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("タイトルを入力してください")
      expect(response.body).to include("定員は0より大きい値にしてください")
    end
  end
end
