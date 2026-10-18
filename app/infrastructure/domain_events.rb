# ドメインイベントを発行し、購読者に届ける
module DomainEvents
  def self.publish(event)
    ActiveSupport::Notifications.instrument(event.class.event_name, event: event)
  end

  def self.subscribe(event_class, subscriber)
    ActiveSupport::Notifications.subscribe(event_class.event_name) do |*, payload|
      subscriber.call(payload[:event])
    end
  end
end
