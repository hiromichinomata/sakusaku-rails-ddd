module Ticketing
  # 予約（Ticketing::Reservation）を reservations テーブルに保存し、読み込む
  class ReservationRepository
    def find(id)
      to_entity(::Reservation.find(id))
    rescue ActiveRecord::RecordNotFound
      raise NotFound, "予約 #{id} が見つかりません"
    end

    # 新しい予約を保存して、ID の付いた予約を返す
    def add(reservation)
      record = ::Reservation.new(event_id: reservation.event_id)
      copy(reservation, to: record)
      record.save!(validate: false)
      to_entity(record)
    rescue ActiveRecord::RecordNotUnique
      raise Reservation::AlreadyReserved
    end

    def save(reservation)
      record = ::Reservation.find(reservation.id)
      copy(reservation, to: record)
      record.save!(validate: false)
    end

    def active_exists?(event_id:, email:)
      ::Reservation.active.exists?(event_id: event_id, email: email.to_s)
    end

    private

    def copy(reservation, to:)
      to.assign_attributes(
        name: reservation.applicant.name,
        email: reservation.applicant.email.to_s,
        quantity: reservation.count.to_i,
        price: reservation.price.yen,
        status: reservation.status.to_s
      )
    end

    def to_entity(record)
      Reservation.new(
        id: record.id,
        event_id: record.event_id,
        applicant: Applicant.new(name: record.name, email: record.email),
        count: ReservationCount.new(record.quantity),
        price: Money.new(record.price),
        status: record.status.to_sym
      )
    end
  end
end
