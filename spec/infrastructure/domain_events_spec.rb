require "rails_helper"

RSpec.describe DomainEvents do
  let(:event) do
    Ticketing::ReservationCreated.new(reservation_id: 1, event_id: 1, status: :pending, occurred_at: Time.current)
  end
  let(:received) { [] }

  around do |example|
    subscription = ActiveSupport::Notifications.subscribe(Ticketing::ReservationCreated.event_name) do |*, payload|
      received << payload[:event]
    end
    example.run
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  it "発行したイベントが、購読者に届く" do
    ApplicationRecord.transaction { described_class.publish(event) }

    expect(received).to eq([ event ])
  end

  it "トランザクションが取り消されたら、イベントは届かない" do
    ApplicationRecord.transaction do
      described_class.publish(event)
      raise ActiveRecord::Rollback
    end

    expect(received).to be_empty
  end
end
