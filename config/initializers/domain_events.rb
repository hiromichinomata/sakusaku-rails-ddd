# ドメインイベントの購読者を登録する。
# 開発中にコードを読み込み直すたびに呼ばれるので、先に同じイベントの購読を外してから登録し直す。
Rails.application.config.to_prepare do
  events = [ Ticketing::ReservationCreated, Ticketing::ReservationConfirmed, Ticketing::ReservationCanceled ]
  events.each { |event_class| ActiveSupport::Notifications.unsubscribe(event_class.event_name) }

  mail = Notification::ReservationMailSubscriber.new
  DomainEvents.subscribe(Ticketing::ReservationCreated, mail)
  DomainEvents.subscribe(Ticketing::ReservationConfirmed, mail)
  DomainEvents.subscribe(Ticketing::ReservationCanceled, Billing::RefundSubscriber.new)
end
