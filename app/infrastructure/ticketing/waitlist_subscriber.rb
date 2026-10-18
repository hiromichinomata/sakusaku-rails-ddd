module Ticketing
  # 予約がキャンセルされた・期限切れになったら（席が戻ったら）、キャンセル待ちに案内するジョブを積む
  class WaitlistSubscriber
    def call(event)
      OfferReleasedSeatsJob.perform_later(event.event_id)
    end
  end
end
