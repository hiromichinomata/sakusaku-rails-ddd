class IdempotencyKey < ApplicationRecord
  def completed?
    response_status.present?
  end
end
