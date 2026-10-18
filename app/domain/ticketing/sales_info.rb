module Ticketing
  # 予約のコンテキストから見たイベント。申込の判断に要る料金と受付期間だけを持つ
  class SalesInfo < Data.define(:event_id, :price, :sales_period); end
end
