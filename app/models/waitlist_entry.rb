class WaitlistEntry < ApplicationRecord
  enum :status, { waiting: "waiting", offered: "offered", skipped: "skipped" }, default: :waiting
end
