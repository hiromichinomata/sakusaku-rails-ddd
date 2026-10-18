require "rails_helper"

RSpec.describe Notification::ReservationMailSubscriber do
  let(:subscriber) { described_class.new }

  def created(status)
    Ticketing::ReservationCreated.new(reservation_id: 1, event_id: 1, status: status, occurred_at: Time.current)
  end

  it "仮予約が作られたら、お支払いのお願いのメールを積む" do
    expect { subscriber.call(created(:pending)) }
      .to have_enqueued_job(Notification::SendReservationMailJob).with(1, "payment_request")
  end

  it "予約確定で作られたら（無料のイベント）、確定のメールを積む" do
    expect { subscriber.call(created(:confirmed)) }
      .to have_enqueued_job(Notification::SendReservationMailJob).with(1, "confirmed")
  end

  it "予約が確定したら、確定のメールを積む" do
    confirmed = Ticketing::ReservationConfirmed.new(reservation_id: 1, event_id: 1, occurred_at: Time.current)

    expect { subscriber.call(confirmed) }
      .to have_enqueued_job(Notification::SendReservationMailJob).with(1, "confirmed")
  end
end
