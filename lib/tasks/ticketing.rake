namespace :ticketing do
  desc "残席の予約済みの人数と、有効な予約の人数の合計がずれていないかを調べる"
  task check_inventory: :environment do
    mismatches = Ticketing::InventoryConsistencyCheck.new.call
    if mismatches.empty?
      puts "ずれはありません"
    else
      mismatches.each do |m|
        puts "イベント #{m.event_id}: 残席の予約済み #{m.recorded}人 / 有効な予約の合計 #{m.actual}人"
      end
      exit 1
    end
  end
end
