require "spec_helper"

# 層とコンテキストの依存のルール（docs/architecture.md）を、ソースコードの文字を調べて守る
RSpec.describe "依存のルール" do
  ROOT = File.expand_path("../..", __dir__)

  def files(*patterns)
    patterns.flat_map { |pattern| Dir[File.join(ROOT, pattern)] }.sort
  end

  # パターンに当てはまる行を「ファイル:行番号: 中身」の一覧にする。許すものは、行から取り除いてから調べる
  def violations(paths, pattern, allowed: [])
    paths.flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, index|
        next if line.strip.start_with?("#")
        next unless allowed.reduce(line) { |rest, allow| rest.gsub(allow, "") }.match?(pattern)

        "#{path.delete_prefix("#{ROOT}/")}:#{index + 1}: #{line.strip}"
      end
    end
  end

  it "ドメイン層は、Rails・Active Record・データベースのモデルを知らない" do
    pattern = /\b(Rails|ActiveRecord|ActiveSupport|ApplicationRecord)\b|(^|[^:\w])(Event|Payment|TicketInventory|IdempotencyKey)\.|(^|[^\w])::Reservation\b/

    expect(violations(files("app/domain/**/*.rb"), pattern)).to eq([])
  end

  it "予約のコンテキストは、決済の入口（Billing::ChargeReservation）だけを使う" do
    ticketing = files("app/domain/ticketing/**/*.rb", "app/usecases/ticketing/**/*.rb", "app/infrastructure/ticketing/**/*.rb")

    expect(violations(ticketing, /\bBilling(::|\.)/, allowed: [ /Billing::ChargeReservation\b/ ])).to eq([])
  end

  it "決済と通知のコンテキストは、予約のドメインイベントだけを知っている" do
    others = files("app/{usecases,infrastructure,jobs}/{billing,notification}/**/*.rb", "app/infrastructure/billing.rb")
    events = /Ticketing::Reservation(Created|Confirmed|Canceled)\b/

    expect(violations(others, /\bTicketing::/, allowed: [ events ])).to eq([])
  end
end
