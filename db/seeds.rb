# bin/rails db:seed で、画面で試すためのイベントを登録する
Event.find_or_create_by!(title: "梅酒づくりワークショップ") do |event|
  event.description = "青梅と氷砂糖で、自分だけの梅酒を仕込みます。"
  event.venue = "うめ公民館"
  event.starts_at = Time.zone.local(2026, 11, 15, 10, 0)
  event.capacity = 20
  event.price = 1500
end

Event.find_or_create_by!(title: "梅林ガイドツアー") do |event|
  event.description = "ガイドと一緒に、梅林を1時間かけて歩きます。"
  event.venue = "うめ公園"
  event.starts_at = Time.zone.local(2026, 12, 6, 13, 0)
  event.capacity = 30
  event.price = 0
end

Event.find_or_create_by!(title: "梅しごと少人数講座") do |event|
  event.description = "定員4名。梅干しの土用干しまでを学びます。"
  event.venue = "うめ公民館 和室"
  event.starts_at = Time.zone.local(2026, 12, 13, 10, 0)
  event.capacity = 4
  event.price = 3000
end

# 予約のコンテキストの残席も用意する
Event.find_each do |event|
  TicketInventory.find_or_create_by!(event: event) { |inventory| inventory.capacity = event.capacity }
end
