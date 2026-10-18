class LotteryEntry < ApplicationRecord
  enum :status, { entered: "entered", won: "won", lost: "lost" }, default: :entered
end
