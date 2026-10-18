require "rails_helper"

RSpec.describe Billing::RefundSubscriber do
  def canceled(refund_amount)
    Ticketing::ReservationCanceled.new(reservation_id: 1, event_id: 1, refund_amount: refund_amount,
                                       occurred_at: Time.current)
  end

  it "返金する金額があれば、返金のジョブを積む" do
    expect { described_class.new.call(canceled(Money.new(3000))) }
      .to have_enqueued_job(Billing::RefundPaymentJob).with(1, 3000)
  end

  it "返金しないキャンセルなら、何もしない" do
    expect { described_class.new.call(canceled(nil)) }.not_to have_enqueued_job(Billing::RefundPaymentJob)
  end
end
