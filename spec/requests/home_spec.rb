require "rails_helper"

RSpec.describe "トップページ", type: :request do
  it "サービス名を表示する" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("うめチケット")
  end
end
