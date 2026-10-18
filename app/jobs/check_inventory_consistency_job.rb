# 残席のずれを定期的に調べ、見つけたら業務のイベントとして記録する（監視でアラートにする）
class CheckInventoryConsistencyJob < ApplicationJob
  queue_as :default

  def perform
    Ticketing::InventoryConsistencyCheck.new.call.each do |mismatch|
      Rails.event.notify("ticketing.inventory_mismatch", **mismatch.to_h)
    end
  end
end
