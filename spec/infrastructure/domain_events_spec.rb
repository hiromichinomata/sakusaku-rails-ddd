require "rails_helper"

RSpec.describe DomainEvents do
  # 本物の購読者に届かないように、テスト専用のイベントを使う
  let(:event_class) do
    Class.new(Data.define(:value)) do
      def self.event_name = "test.something_happened"
    end
  end
  let(:event) { event_class.new(value: 1) }
  let(:received) { [] }

  around do |example|
    subscription = ActiveSupport::Notifications.subscribe("test.something_happened") do |*, payload|
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
