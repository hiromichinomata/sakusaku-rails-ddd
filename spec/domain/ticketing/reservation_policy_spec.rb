require "domain_helper"

RSpec.describe Ticketing::ReservationPolicy do
  def count(value) = Ticketing::ReservationCount.new(value)

  it "主催者が決めていなければ、1回4人まで・返金は72時間前まで" do
    expect(described_class::DEFAULT).to have_attributes(max_count: 4, refund_hours_before_start: 72)
  end

  it "1回の人数の上限を超えたら、予約できない（R-02）" do
    policy = described_class.new(max_count: 6, refund_hours_before_start: 72)

    expect { policy.ensure_count_allowed!(count(6)) }.not_to raise_error
    expect { policy.ensure_count_allowed!(count(7)) }
      .to raise_error(Ticketing::ReservationPolicy::TooManyAttendees, "1回の予約は6人までです")
  end

  it "返金期限は、主催者が決めた時間前（R-09）" do
    starts_at = Time.new(2026, 11, 15, 10, 0, 0, "+09:00")
    deadline = described_class.new(max_count: 4, refund_hours_before_start: 24).cancellation_deadline(starts_at)

    expect(deadline.refund_until).to eq(Time.new(2026, 11, 14, 10, 0, 0, "+09:00"))
  end

  it "サービス全体の上限（10人）を超える上限は決められない" do
    expect { described_class.new(max_count: 11, refund_hours_before_start: 72) }.to raise_error(ArgumentError)
  end
end
