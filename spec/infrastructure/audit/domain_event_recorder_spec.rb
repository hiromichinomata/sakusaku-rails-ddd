require "rails_helper"

RSpec.describe Audit::DomainEventRecorder do
  # Rails.event に流れたイベントを集める
  let(:collector) do
    Class.new do
      attr_reader :events

      def initialize
        @events = []
      end

      def emit(event)
        events << event
      end
    end.new
  end
  let(:reported) { collector.events }

  around do |example|
    Rails.event.subscribe(collector)
    example.run
  ensure
    Rails.event.unsubscribe(collector)
  end

  it "ドメインイベントを、業務の名前のイベントとして記録する。金額は円の数にする" do
    event = Ticketing::ReservationCanceled.new(reservation_id: 1, event_id: 2, refund_amount: Money.new(3000),
                                               occurred_at: Time.current)

    described_class.new.call(event)

    expect(reported.last).to include(name: "ticketing.reservation_canceled")
    expect(reported.last[:payload]).to include(reservation_id: 1, event_id: 2, refund_amount: 3000)
  end

  it "ドメインイベントには、申込者の名前やメールアドレスを入れていない" do
    events = [ Ticketing::ReservationCreated, Ticketing::ReservationConfirmed, Ticketing::ReservationCanceled,
               Ticketing::ReservationExpired ]

    expect(events.flat_map(&:members)).not_to include(:name, :email, :applicant)
  end

  it "うっかりメールアドレスを記録しても、伏せられる" do
    Rails.event.notify("ticketing.something", reservation_id: 1, email: "hatsuka@example.com")

    expect(reported.last[:payload]).to eq(reservation_id: 1, email: "[FILTERED]")
  end
end
