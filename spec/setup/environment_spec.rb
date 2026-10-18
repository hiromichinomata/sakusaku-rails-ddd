require "rails_helper"

RSpec.describe "開発環境" do
  it "Ruby 4.0 で動いている" do
    expect(RUBY_VERSION).to start_with("4.0")
  end

  it "Rails 8.1 で動いている" do
    expect(Rails.version).to start_with("8.1")
  end

  it "テスト用の PostgreSQL に接続できる" do
    connection = ActiveRecord::Base.connection
    expect(connection.adapter_name).to eq("PostgreSQL")
    expect(connection.current_database).to eq("ume_tickets_test")
  end
end
