module Billing
  # カードが使えなかった。やり直しても同じ結果になる
  class CardDeclined < StandardError; end
end
