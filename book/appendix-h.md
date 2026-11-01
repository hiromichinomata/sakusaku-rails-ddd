# 付録H　演習問題と解答例

**初花**: 本編で「付録Hの演習」と言っていたものを、ここでやるんだね。

**マリゴールド**: そう。前半の2問はコードを書く演習、後半の3問は紙の上で設計する演習だよ。解答は一例だから、まず自分で考えてから読んでね。

---

## 演習1　抽選の当選者の支払い期限を24時間にする

第21章では、抽選の当選者の支払い期限が、先着と同じ「仮予約から15分」のままでした。当選者の支払い期限を、**抽選から24時間後** にしてください。

- 先着の申込とキャンセル待ちの案内は、今までどおり15分
- 期限切れのジョブは、当選者の仮予約を1時間後に期限切れにしない
- 画面とメールの「◯時◯分までにお支払いください」も、予約ごとの期限を表示する

**ヒント**: 今の支払い期限は、予約の作成時刻から **計算** しています。予約ごとに違う期限を持つには、何を保存すればよいでしょうか。

### 解答例

#### テストを先に書く

ドメインのテストで、期限までの時間を決めて予約を作れることを書きます。

`spec/domain/ticketing/reservation_transitions_spec.rb`（抜粋）:

```ruby
  it "支払い期限までの時間を決めて、予約を作れる（抽選の当選者は24時間。R-13）" do
    target = described_class.apply(event_id: 1, applicant: Ticketing::Applicant.new(name: "初花", email: "hatsuka@example.com"),
                                   count: Ticketing::ReservationCount.new(2), price: Money.new(1500),
                                   reserved_at: reserved_at, payment_window: 24 * 60 * 60)

    expect(target.payment_deadline).to eq(reserved_at + (24 * 60 * 60))
  end
```

ユースケースのテストで、抽選の当選者の期限と、期限切れのジョブとのつながりを書きます。

`spec/usecases/ticketing/lottery_usecases_spec.rb`（抜粋）:

```ruby
    it "当選者の支払い期限は、抽選から24時間後（R-13）" do
      now = Time.current
      described_class.new.call(event_id: event.id, random: Random.new(7), now: now)

      Reservation.where(event: event).find_each do |reservation|
        expect(reservation.payment_deadline).to be_within(1.second).of(now + 24.hours)
      end
    end

    it "当選者の仮予約は、1時間たっても期限切れにならない" do
      described_class.new.call(event_id: event.id, random: Random.new(7))

      ExpirePendingReservationsJob.perform_now(now: 1.hour.from_now)

      expect(Reservation.pending.count).to eq(LotteryEntry.won.count)
    end
```

```bash
bundle exec rspec spec/domain/ticketing/reservation_transitions_spec.rb spec/usecases/ticketing/lottery_usecases_spec.rb
```

```text
  1) Ticketing::Reservation の状態遷移 支払い期限までの時間を決めて、予約を作れる（抽選の当選者は24時間。R-13）
     Failure/Error:
       def self.apply(event_id:, applicant:, count:, price:, reserved_at:)
         new(event_id: event_id, applicant: applicant, count: count, price: price, reserved_at: reserved_at,
             status: price.zero? ? :confirmed : :pending)
       end

     ArgumentError:
       unknown keyword: :payment_window

  2) 抽選販売のユースケース Ticketing::DrawLottery 当選者の支払い期限は、抽選から24時間後（R-13）
     Failure/Error: expect(reservation.payment_deadline).to be_within(1.second).of(now + 24.hours)
       expected 2026-11-01 10:15:00.000000000 +0900 to be within 1 of 2026-11-02 10:00:00.000000000 +0900

  3) 抽選販売のユースケース Ticketing::DrawLottery 当選者の仮予約は、1時間たっても期限切れにならない
     Failure/Error: expect(Reservation.pending.count).to eq(LotteryEntry.won.count)

       expected: 2
            got: 0

       (compared using ==)

Finished in 0.41551 seconds (files took 0.78472 seconds to load)
19 examples, 3 failures
```

（失敗の一覧の前後を省略しています。テストの「今」は、2026年11月1日10時に固定しています。）

3つ目の失敗が大事です。当選者の仮予約が、1時間後の期限切れのジョブで、2件とも期限切れになってしまいました。

#### 期限を予約ごとに保存する

予約のテーブルに、支払い期限の列を足します。これまでの予約は、作成から15分後で埋めます。

`db/migrate/20261019090000_add_payment_due_at_to_reservations.rb`:

```ruby
class AddPaymentDueAtToReservations < ActiveRecord::Migration[8.1]
  def up
    # 支払い期限を、予約ごとに持つ。これまでの予約は、作成から15分後
    add_column :reservations, :payment_due_at, :datetime
    execute "UPDATE reservations SET payment_due_at = created_at + interval '15 minutes'"
    change_column_null :reservations, :payment_due_at, false
  end

  def down
    remove_column :reservations, :payment_due_at
  end
end
```

エンティティは、支払い期限を計算するのではなく、値として持つようにします。`apply` では、期限までの時間（`payment_window`）を受け取れるようにし、渡されなければ15分にします。

`app/domain/ticketing/reservation.rb`（抜粋）:

```ruby
    PAYMENT_WINDOW = 15 * 60 # 支払い期限は、ふつうは仮予約の作成から15分後（秒）

    attr_reader :id, :event_id, :applicant, :count, :price, :status, :reserved_at, :payment_deadline

    # 申込から、新しい予約を作る。有料なら仮予約（R-05）、無料なら予約確定（R-06）。
    # payment_window は、支払い期限までの時間（抽選の当選者は24時間。R-13）
    def self.apply(event_id:, applicant:, count:, price:, reserved_at:, payment_window: PAYMENT_WINDOW)
      new(event_id: event_id, applicant: applicant, count: count, price: price, reserved_at: reserved_at,
          payment_deadline: reserved_at + payment_window, status: price.zero? ? :confirmed : :pending)
    end

    def initialize(event_id:, applicant:, count:, price:, reserved_at: nil, payment_deadline: nil, id: nil,
                   status: :pending)
      @id = id
      @event_id = event_id
      @applicant = applicant
      @count = count
      @price = price
      @reserved_at = reserved_at
      @payment_deadline = payment_deadline || (reserved_at && reserved_at + PAYMENT_WINDOW)
      @status = status
    end
```

`confirm`・`expire`・`ensure_payable!` は `payment_deadline` を読んでいるだけなので、変えなくて済みます。当選者の期限は、抽選の側に決めます。

`app/domain/ticketing/lottery.rb`（抜粋）:

```ruby
    Result = Data.define(:winners, :losers)
    PAYMENT_WINDOW = 24 * 60 * 60 # 当選者の支払い期限は、抽選から24時間後（秒）
```

`app/usecases/ticketing/allocate_seats.rb`（抜粋）:

```ruby
    def call(inventory:, applicant:, count:, price:, now:, payment_window: Reservation::PAYMENT_WINDOW)
      inventory.reserve(count)
      reservation = @reservations.add(
        Reservation.apply(event_id: inventory.event_id, applicant: applicant, count: count, price: price,
                          reserved_at: now, payment_window: payment_window)
      )
```

`app/usecases/ticketing/draw_lottery.rb`（抜粋）:

```ruby
          reservation = @allocate.call(inventory: inventory, applicant: entry.applicant, count: entry.count,
                                       price: price, now: now, payment_window: Lottery::PAYMENT_WINDOW)
```

リポジトリで、列とエンティティを対応させます。

`app/infrastructure/ticketing/reservation_repository.rb`（抜粋）:

```ruby
        created_at: reservation.reserved_at,
        payment_due_at: reservation.payment_deadline
      )
```

`app/infrastructure/ticketing/reservation_repository.rb`（抜粋）:

```ruby
        reserved_at: record.created_at,
        payment_deadline: record.payment_due_at
      )
```

期限切れのジョブは、作成時刻から計算するのをやめて、保存した期限で探します。

`app/jobs/expire_pending_reservations_job.rb`:

```ruby
class ExpirePendingReservationsJob < ApplicationJob
  queue_as :default

  # 支払い期限を過ぎた仮予約を、1件ずつ期限切れにする
  def perform(now: Time.current)
    Reservation.pending.where(payment_due_at: ...now).find_each do |record|
      Ticketing::ExpireReservation.new.call(reservation_id: record.id, now: now)
    end
  end
end
```

画面とメールは `Reservation#payment_deadline` を表示しているので、保存の入れ物の側を、列を読むように変えるだけです。

`app/models/reservation.rb`（抜粋）:

```ruby
  def payment_deadline
    payment_due_at
  end
```

#### テストの準備を合わせる

ここで全部のテストを流すと、202件中5件が落ちました。

```text
rspec ./spec/infrastructure/ticketing/reservation_repository_spec.rb:17 # Ticketing::ReservationRepository#add 新しい予約を保存して、IDの付いた予約を返す
rspec ./spec/infrastructure/ticketing/reservation_repository_spec.rb:25 # Ticketing::ReservationRepository#add 同じメールアドレスの有効な予約があれば Ticketing::Reservation::AlreadyReserved
rspec ./spec/infrastructure/ticketing/reservation_repository_spec.rb:33 # Ticketing::ReservationRepository#find 保存した予約を、ドメインのオブジェクトとして読み込む
rspec ./spec/infrastructure/ticketing/reservation_repository_spec.rb:49 # Ticketing::ReservationRepository#active_exists? 同じイベント・同じメールアドレスの有効な予約があるかを調べる
rspec ./spec/requests/payments_spec.rb:46 # お支払い POST /reservations/:reservation_id/payment 予約から15分を過ぎると、支払えずに期限切れになる
```

```text
     ActiveRecord::NotNullViolation:
       PG::NotNullViolation: ERROR:  null value in column "payment_due_at" of relation "reservations" violates not-null constraint
```

どれも、テストの準備で「予約の作成時刻だけ」を決めていたものです。リポジトリのテストは作成時刻なしでエンティティを作っていたので、作成時刻を渡します。支払いのリクエストスペックは作成時刻だけを16分前にしていたので、期限も過ぎた時刻にします。ファクトリでは、作成時刻から15分後を期限にします。

`spec/infrastructure/ticketing/reservation_repository_spec.rb`（抜粋）:

```ruby
      price: Money.new(1500),
      reserved_at: Time.current
    )
```

`spec/requests/payments_spec.rb`（抜粋）:

```ruby
      reservation.update!(created_at: 16.minutes.ago, payment_due_at: 1.minute.ago)
```

`spec/factories/reservations.rb`:

```ruby
FactoryBot.define do
  factory :reservation do
    event
    name { "初花" }
    sequence(:email) { |n| "attendee#{n}@example.com" }
    quantity { 1 }
    price { event.price } # 申し込んだときの料金（R-12）
    payment_due_at { (created_at || Time.current) + Ticketing::Reservation::PAYMENT_WINDOW }
  end
end
```

```text
Finished in 10.22 seconds (files took 1.4 seconds to load)
202 examples, 0 failures
```

ルールの一覧（R-05・R-13）と、用語集の「支払い期限」も書き換えます。

`docs/domain/rules.md`（抜粋）:

```markdown
| R-05 | 有料イベントの申込は仮予約になる。支払い期限（仮予約の作成から15分後。抽選の当選者は24時間後）まで（ちょうどを含む）に支払うと、予約確定になる |
```

#### 考え方

**初花**: 期限を「計算するもの」から「予約が持つ値」に変えたら、確定・キャンセル・期限切れの判断は1行も変えずに済んだ。

**マリゴールド**: エンティティの外から期限を読むところが、`payment_deadline` の1か所だけだったからだね。逆に、期限切れのジョブは作成時刻から自分で計算していたから、直す必要があった。**同じルールを2か所で計算していると、変えるときに両方を探すことになる**、という第3章の教訓が、ここでも見えたよ。

---

## 演習2　先着の申込も `AllocateSeats` を使う

第21章では、`AllocateSeats` を抽選とキャンセル待ちだけで使い、先着の申込（`ReserveSeats`）には寄せませんでした。`ReserveSeats` も `AllocateSeats` を使うように書き換えてください。ふるまいは変えず、テストはそのまま通ることを確かめます。

### 解答例

`app/usecases/ticketing/reserve_seats.rb`:

```ruby
module Ticketing
  # 申込のユースケース。席を押さえて、予約を作る
  class ReserveSeats
    def initialize(inventories: InventoryRepository.new, reservations: ReservationRepository.new,
                   sales_infos: SalesInfoReader.new)
      @inventories = inventories
      @sales_infos = sales_infos
      @double_booking = DoubleBookingCheck.new(reservations)
      @allocate = AllocateSeats.new(reservations: reservations)
    end

    def call(event_id:, name:, email:, count:, now: Time.current)
      applicant = Applicant.new(name: name, email: email)
      count = ReservationCount.new(count)

      ApplicationRecord.transaction do
        sales_info = @sales_infos.find(event_id)
        sales_info.sales_period.ensure_open!(now)
        sales_info.policy.ensure_count_allowed!(count)
        @double_booking.ensure_not_double_booked!(event_id: event_id, email: applicant.email)

        inventory = @inventories.find(event_id, lock: true)
        inventory.ensure_first_come!
        reservation = @allocate.call(inventory: inventory, applicant: applicant, count: count,
                                     price: sales_info.price, now: now)
        @inventories.save(inventory)
        reservation
      end
    end
  end
end
```

`app/usecases/ticketing/allocate_seats.rb`（抜粋）:

```ruby
  # 先着の申込・抽選の当選・キャンセル待ちの案内で、申込者のために席を押さえて予約を作る。
```

```bash
bundle exec rspec
```

```text
Finished in 8.57 seconds (files took 1.4 seconds to load)
202 examples, 0 failures
```

#### 考え方

**初花**: 残席の保存が、予約の保存より後になったけど、いいの？

**マリゴールド**: 同じトランザクションの中だから、どちらかが失敗すれば両方とも取り消されるよ。並行処理のテスト（第16章）も通っているから、ロックの効き方も変わっていない。それに、演習1のあとだから、`payment_window` を渡さなければ15分になることも、`AllocateSeats` の側で決まっているね。

第21章で寄せなかったのは、`ReserveSeats` だけが、受付期間・主催者の上限・二重予約を確かめていたからです。寄せてみると、違うのは **確かめる部分** だけで、席を押さえて予約を作る部分は同じだと分かりました。共通の部品は、こうして「同じだ」と確かめてから寄せると、無理がありません。

---

## 演習3　抽選に外れた人を、自動でキャンセル待ちにする

主催者から「抽選に外れた人を、自動でキャンセル待ちにしたい」と頼まれました。紙の上で設計してください。

1. どのコンテキストの、どの集約が変わりますか
2. 新しいドメインイベントは要りますか
3. 業務の人に確かめるべきことは何ですか

### 解答例

1. 予約のコンテキストの中で完結します。変わるのは、抽選（`DrawLottery`）とキャンセル待ち（`Waitlist`）のつながりです。今のキャンセル待ちは「満席のときだけ登録できる」（`JoinWaitlist` の `SeatsAvailable`）ので、抽選のあとは残席0になる点は合っていますが、**入りきらない人数の申込が落選して、残席が残っている** ときは、そのまま申し込んでもらうべきかを決める必要があります
2. 「抽選で落選した」（`LotteryLost` など）というドメインイベントを発行し、キャンセル待ちに登録する購読者を足す形にすると、`DrawLottery` はキャンセル待ちを知らずに済みます（第21章の `WaitlistSubscriber` と同じ考え方）。同じコンテキストの中なので、`DrawLottery` から `JoinWaitlist` を直接呼ぶ案もあり、どちらにしたかを ADR に残します
3. 確かめることの例：
   - 落選者全員を登録するか、希望した人だけにするか（自動で登録されて、突然仮予約のメールが届くと驚く人がいる）
   - キャンセル待ちの順番は、抽選の順か、申込の順か
   - 抽選の申込と、キャンセル待ちの登録で、人数を変えてよいか

---

## 演習4　主催者が途中で料金を変えたら

主催者が、販売中のイベントの料金を1,500円から2,000円に変えました。

1. すでに仮予約の人は、いくら払いますか
2. すでに予約確定の人がキャンセルしたら、いくら返金しますか
3. 今のコードで、どこを見れば答えが分かりますか

### 解答例

1. 1,500円（× 人数）です。予約には、申し込んだときの料金を記録しています（R-12。第10章）
2. 返金期限までなら、1,500円（× 人数）の全額です。返金する金額は、予約に記録した料金から計算した支払い金額（`total_price`）です（`CancelReservation`。第14章）
3. `Ticketing::Reservation#total_price`（予約に記録した `price` × 人数）と、`Ticketing::ReservationRepository` の `price: Money.new(record.price)`、そして `docs/domain/rules.md` の R-12 です

**考え方**: 第3章のモデルの `total_price` は `event.price * quantity` だったので、料金を変えると、仮予約の人の支払い金額まで変わっていました。「いつの料金か」を業務の人と決め、ルールの一覧に書き、予約に値として残したことで、この質問にコードを読まずに答えられます。もし「値上げした料金をもらいたい」と言われたら、それは新しいルールなので、ルールの一覧とテストから変えます。

---

## 演習5　複数のイベントをまとめて予約する

「親子で参加する、午前と午後の2つの講座を、まとめて予約したい。片方だけ取れても困る」という要件が来ました。紙の上で設計してください。

### 解答例

- **新しい言葉**: 「まとめて申込」（仮の名前）を用語集に足し、1件の予約と何が違うかを決めます。支払いは1回か、予約ごとか。キャンセルは片方だけできるか
- **集約**: 残席の集約は、イベントごとに1つです。まとめて申込では、**2つの集約を1回のトランザクションで変える** ことになります。原則（1回に1つ）の例外なので、理由（片方だけ取れても困る）を ADR に書きます
- **ロックの順番**: 2つの残席を `FOR UPDATE` でロックするときは、いつもイベント ID の小さい順にロックします。順番がばらばらだと、2人が逆の順でロックしてデッドロックになることがあります（第16章）
- **ユースケース**: `ReserveSeats` を2回呼ぶのではなく、新しいユースケースにして、1つのトランザクションの中で、両方の確かめ → 両方の `AllocateSeats` を行います（演習2のおかげで、席を押さえる部分は使い回せます）
- **テスト**: 「片方が満席なら、もう片方も予約されない」をユースケースのテストで、同時の申込を並行処理のテストで確かめます

**考え方**: 「片方だけ取れても困る」が本当に必要かを、最初に業務の人と確かめるのが大事です。「取れなかったら、もう片方はキャンセルしてよい」なら、2回の申込と、失敗したときのキャンセル（あとで揃う整合性）で作れて、集約の原則を曲げずに済みます。
