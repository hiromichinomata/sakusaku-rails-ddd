# 付録D　Active RecordモデルとPOROの比較コード

**初花**: 第3章の Fat Model と、最後の形を、並べて見比べたい。

**マリゴールド**: 付録Dは、予約のクラスの **ビフォー・アフター** だよ。同じ予約の業務ルールが、どこに移ったかを追いかけてみよう。

---

## D.1　ビフォー：Active Record のモデルに全部入り（第3章）

第3章の終わりの、予約のモデルです。形の検証・業務のルール・状態・メールの送信が、1つのクラスに入っています。

`app/models/reservation.rb`:

```ruby
class Reservation < ApplicationRecord
  MAX_QUANTITY = 4

  belongs_to :event
  has_one :payment, dependent: :destroy

  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    canceled: "canceled",
    expired: "expired"
  }, default: :pending

  scope :active, -> { where(status: %w[pending confirmed]) }

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :event_id, conditions: -> { active }, message: :already_reserved },
                    on: :create
  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_QUANTITY }
  validate :quantity_within_remaining_seats
  validate :event_accepting_reservations, on: :create

  before_create :confirm_if_free
  after_create_commit :send_payment_request_mail, if: :pending?
  after_update_commit :send_confirmed_mail, if: -> { saved_change_to_status?(to: "confirmed") }

  def total_price
    event.price * quantity
  end

  private

  def quantity_within_remaining_seats
    return if event.nil? || quantity.nil?

    remaining = event.capacity - event.reservations.active.where.not(id: id).sum(:quantity)
    if quantity > remaining
      errors.add(:quantity, :exceeds_remaining_seats, count: remaining)
    end
  end

  def event_accepting_reservations
    return if event.nil?

    errors.add(:base, :reservation_closed) if event.starts_at <= Time.current
  end

  def confirm_if_free
    self.status = :confirmed if event.price.zero?
  end

  def send_payment_request_mail
    ReservationMailer.with(reservation: self).payment_request.deliver_later
  end

  def send_confirmed_mail
    ReservationMailer.with(reservation: self).confirmed.deliver_later
  end
end
```

---

## D.2　アフター：PORO のエンティティ（第21章）

予約の業務の判断は、Rails を継承しない Ruby のクラスに移りました。状態は、決まった遷移のメソッドでしか変えられません。

`app/domain/ticketing/reservation.rb`（抜粋）:

```ruby
    # 申込から、新しい予約を作る。有料なら仮予約（R-05）、無料なら予約確定（R-06）
    def self.apply(event_id:, applicant:, count:, price:, reserved_at:)
      new(event_id: event_id, applicant: applicant, count: count, price: price, reserved_at: reserved_at,
          status: price.zero? ? :confirmed : :pending)
    end
```

`app/domain/ticketing/reservation.rb`（抜粋）:

```ruby
    # 支払いが済んだ（R-05・R-10）
    def confirm(now:)
      raise InvalidTransition.new(status_name, "確定") unless status == :pending
      raise PaymentDeadlinePassed if now > payment_deadline

      @status = :confirmed
    end

    # 申込者が取りやめた（R-08）
    def cancel
      raise InvalidTransition.new(status_name, "キャンセル") unless %i[pending confirmed].include?(status)

      @status = :canceled
    end
```

## D.3　アフター：保存の入れ物になった Active Record のモデル

同じ名前の Active Record のモデルは、保存と、画面で表示するための読み出しだけになりました。

`app/models/reservation.rb`:

```ruby
class Reservation < ApplicationRecord
  belongs_to :event

  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    canceled: "canceled",
    expired: "expired"
  }, default: :pending

  scope :active, -> { where(status: %w[pending confirmed]) }

  def total_price
    Money.new(price) * quantity
  end

  def payment_deadline
    Ticketing::Reservation.payment_deadline_for(created_at)
  end
end
```

2つをつなぐのは、リポジトリです。テーブルの行を、値オブジェクトを使ったエンティティに組み立てます。

`app/infrastructure/ticketing/reservation_repository.rb`（抜粋）:

```ruby
    def to_entity(record)
      Reservation.new(
        id: record.id,
        event_id: record.event_id,
        applicant: Applicant.new(name: record.name, email: record.email),
        count: ReservationCount.new(record.quantity),
        price: Money.new(record.price),
        status: record.status.to_sym,
        reserved_at: record.created_at
      )
    end
```

---

## D.4　ルールの引っ越し先

第3章のモデルの1行1行が、どこへ移ったかの表です。

| 第3章のモデルの行 | 第21章での置き場所 | 章 |
|----------------|----------------|----|
| `MAX_QUANTITY = 4`・`validates :quantity` | `ReservationCount`（1〜10人）と `ReservationPolicy`（主催者の上限） | 8・21 |
| `validates :name`・`:email`（形） | `ReservationForm`・`Applicant`・`EmailAddress` | 8・13 |
| `validates :email, uniqueness:` | `DoubleBookingCheck` とユニーク制約 | 11・16 |
| `validate :quantity_within_remaining_seats` | 残席の集約 `Inventory#reserve` と CHECK 制約 | 9・16 |
| `validate :event_accepting_reservations` | `SalesPeriod#ensure_open!` | 11 |
| `before_create :confirm_if_free` | `Reservation.apply` | 11 |
| `after_create_commit`・`after_update_commit` のメール | ドメインイベントと `Notification::ReservationMailSubscriber` | 12 |
| `enum :status` を自由に書き換える | `confirm`・`cancel`・`expire` | 14 |
| `has_one :payment` | 決済のコンテキストの `Payment`（予約とは ID でつなぐ） | 18 |
| `total_price`（`event.price * quantity`） | 予約に記録した料金 × 人数（`Money`） | 8・10 |

---

## D.5　比べてみる

| 観点 | Active Record のモデル | PORO のエンティティ |
|-----|-------------------|-----------------|
| 書く量 | 少ない。保存も検証も Rails がやってくれる | 多い。変換のためのリポジトリが要る |
| 読みやすさ | 小さいうちは読みやすい。ルールが増えるとコールバックと検証が絡み合う | ルールが業務の言葉のメソッドになる（`cancel`・`confirm`） |
| 状態の守り方 | `update!(status: ...)` で、どこからでも書き換えられる | 遷移のメソッドの外からは変えられない |
| テスト | データベースが要る | Rails もデータベースも要らない |
| 向いている場所 | 支援サブドメイン（イベント管理） | コアドメイン（予約） |

テストの速さを比べます。予約のエンティティのテスト（Rails なし）と、予約のモデルのテスト（データベースあり）です。

```bash
bundle exec rspec spec/domain/ticketing/reservation_spec.rb spec/domain/ticketing/reservation_transitions_spec.rb
```

```text
Finished in 0.00786 seconds (files took 0.08404 seconds to load)
17 examples, 0 failures
```

```bash
bundle exec rspec spec/models
```

```text
Finished in 0.15357 seconds (files took 0.94621 seconds to load)
6 examples, 0 failures
```

**初花**: エンティティは17件で0.008秒、モデルは6件で0.15秒。読み込みも、0.08秒と0.9秒で10倍以上違う。

**マリゴールド**: ただし、どちらが正しいという話ではないよ。イベント管理のように、ルールが少なく、画面の入力をそのまま保存すればよい場所なら、Active Record のモデルのほうがずっと速く作れる。第5章で決めたとおり、**手間をかける場所を選ぶ** のが大事なんだ。
