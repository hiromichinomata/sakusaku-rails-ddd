# ドメインイベントを発行し、購読者に届ける。
# トランザクションの中で発行されたイベントは、コミットのあとで届ける（取り消されたら届けない）。
module DomainEvents
  def self.publish(event)
    ActiveRecord.after_all_transactions_commit do
      ActiveSupport::Notifications.instrument(event.class.event_name, event: event)
    end
  end

  def self.subscribe(event_class, subscriber)
    ActiveSupport::Notifications.subscribe(event_class.event_name) do |*, payload|
      subscriber.call(payload[:event])
    end
  end
end
