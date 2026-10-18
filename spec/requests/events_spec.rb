require "rails_helper"

RSpec.describe "イベント", type: :request do
  let!(:event) do
    Event.create!(
      title: "梅酒づくりワークショップ",
      description: "青梅と氷砂糖で、自分だけの梅酒を仕込みます。",
      venue: "うめ公民館",
      starts_at: Time.zone.local(2026, 11, 15, 10, 0),
      capacity: 20,
      price: 1500
    )
  end

  describe "GET /events" do
    it "イベントのタイトルを一覧に表示する" do
      get events_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("梅酒づくりワークショップ")
    end
  end

  describe "GET /events/:id" do
    it "イベントの詳細を表示する" do
      get event_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("うめ公民館")
      expect(response.body).to include("2026年11月15日 10:00")
      expect(response.body).to include("定員 20人")
      expect(response.body).to include("1,500円")
    end
  end
end
