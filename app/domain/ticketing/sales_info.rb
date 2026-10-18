module Ticketing
  # 予約のコンテキストから見たイベント。申込とキャンセルの判断に要る、料金・受付期間・返金期限と、主催者のルールだけを持つ
  class SalesInfo < Data.define(:event_id, :price, :sales_period, :cancellation_deadline, :policy); end
end
