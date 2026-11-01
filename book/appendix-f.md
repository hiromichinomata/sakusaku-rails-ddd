# 付録F　テストコマンドとデバッグ手順

**初花**: テストを流すコマンドと、困ったときの調べ方をまとめておきたい。

**マリゴールド**: 付録Fは、うめチケットで使った **コマンドの一覧と、調べ方の手順** だよ。出力は、第21章を終えたアプリで取ったものだね。

---

## F.1　テストを流す

| 用途 | コマンド |
|------|---------|
| 全部 | `bundle exec rspec` |
| ドメインだけ（ルールを変えたとき） | `bundle exec rspec spec/domain` |
| 1つのファイル | `bundle exec rspec spec/domain/ticketing/inventory_spec.rb` |
| 1つの例（行番号） | `bundle exec rspec spec/requests/reservations_spec.rb:45` |
| 例の名前を表示する | `-fd`（`--format documentation`） |
| 並行処理だけ・並行処理を外して | `--tag concurrency`・`--tag ~concurrency` |
| 遅い例を探す | `--profile 3` |
| コミットの前 | `bin/ci` |

### ドメインだけ

```bash
bundle exec rspec spec/domain
```

```text
Finished in 0.01108 seconds (files took 0.08402 seconds to load)
57 examples, 0 failures
```

### 1つのファイルを、例の名前つきで

```bash
bundle exec rspec spec/domain/ticketing/inventory_spec.rb -fd
```

```text
Ticketing::Inventory
  残席は、定員 − 予約済みの人数
  予約済みの人数が定員を超えた残席は作れない
  #reserve
    残席の範囲なら、予約済みの人数が増える
    残席を超える人数は予約できず、予約済みの人数も変わらない
  #release
    キャンセルや期限切れで、席を戻す
  #change_capacity
    予約済みの人数ちょうどまでは減らせる（R-11）
    予約済みの人数より少なくはできない（R-11）

Finished in 0.0057 seconds (files took 0.07933 seconds to load)
7 examples, 0 failures
```

### 1つの例だけ

失敗した例は、最後に `rspec ./spec/...:行番号` の形で表示されます。その行をそのまま流すと、その例だけを確かめられます。

```bash
bundle exec rspec spec/requests/reservations_spec.rb:45
```

```text
Run options: include {locations: {"./spec/requests/reservations_spec.rb" => [45]}}
.

Finished in 0.16941 seconds (files took 0.89972 seconds to load)
1 example, 0 failures
```

### 並行処理を分けて

```bash
bundle exec rspec --tag concurrency
```

```text
Finished in 1.4 seconds (files took 1.43 seconds to load)
2 examples, 0 failures
```

```bash
bundle exec rspec --tag ~concurrency
```

```text
Finished in 7.1 seconds (files took 1.34 seconds to load)
197 examples, 0 failures
```

### 遅い例を探す

```bash
bundle exec rspec --profile 3
```

```text
Top 3 slowest examples (1.61 seconds, 18.5% of total time):
  同時の申込 残り1席に2人が同時に申し込んでも、定員を超えない
    1.19 seconds ./spec/concurrency/reserve_seats_concurrency_spec.rb:23
  同じメールアドレスの同時の申込 二重予約のチェックを2人ともすり抜けても、データベースが1件だけにする
    0.21766 seconds ./spec/concurrency/double_booking_concurrency_spec.rb:8
  キャンセル PATCH /reservations/:id/cancel 開催3日前より前なら、キャンセルして全額返金する
    0.19688 seconds ./spec/requests/cancellations_spec.rb:14

Top 3 slowest example groups:
  同時の申込
    1.19 seconds average (1.19 seconds / 1 example) ./spec/concurrency/reserve_seats_concurrency_spec.rb:3
  同じメールアドレスの同時の申込
    0.21782 seconds average (0.21782 seconds / 1 example) ./spec/concurrency/double_booking_concurrency_spec.rb:3
  キャンセル
    0.13387 seconds average (0.93708 seconds / 7 examples) ./spec/requests/cancellations_spec.rb:3

Finished in 8.7 seconds (files took 1.38 seconds to load)
199 examples, 0 failures
```

**初花**: 全部で8.7秒のうち、1.2秒が同時の申込のテストなんだ。

**マリゴールド**: 2つのスレッドを待ち合わせて、本物のロックを待つからね。ふだんの開発では `--tag ~concurrency` で外して、コミットの前の `bin/ci` で全部を流す、という使い分けができるよ。

---

## F.2　ドメインのテストを「Rails なし」で流す理由

`bin/ci` は、全部のテストとは別に、ドメインのテストだけを先に流します（第17章）。その理由が分かる実験をしてみます。申込者の名前の確かめ方を、Rails でよく使う `blank?` に書き換えてみます（試したら元に戻します）。

```diff
-      raise ArgumentError, "申込者の名前を指定してください" if name.to_s.strip.empty?
+      raise ArgumentError, "申込者の名前を指定してください" if name.blank?
```

全部のテストを流すと、通ってしまいます。

```bash
bundle exec rspec
```

```text
Finished in 7.71 seconds (files took 1.64 seconds to load)
199 examples, 0 failures
```

ドメインのテストだけを流すと、落ちます（バックトレースの一部を省略しています）。

```bash
bundle exec rspec spec/domain/ticketing/applicant_spec.rb
```

```text
  1) Ticketing::Applicant 名前とメールアドレスを持つ。メールアドレスは EmailAddress にする
     Failure/Error: raise ArgumentError, "申込者の名前を指定してください" if name.blank?

     NoMethodError:
       undefined method 'blank?' for an instance of String
     # ./app/domain/ticketing/applicant.rb:5:in 'Ticketing::Applicant#initialize'

  ...

Finished in 0.00993 seconds (files took 0.05283 seconds to load)
2 examples, 2 failures
```

**初花**: `blank?` は Active Support のメソッドだから、Rails を読み込まないと使えないんだ。全部を流すと、ほかのスペックが Rails を読み込むから通っちゃう。

**マリゴールド**: そう。依存のルールのテスト（第19章）は `ActiveRecord` のような名前は見つけられるけど、`blank?` のような、Ruby の標準のクラスに足されたメソッドまでは見つけられない。**ドメインのテストを単独で流すこと自体が、Rails に依存していないことのテスト** になっているんだ。

---

## F.3　動いているアプリを調べる

### エンティティと集約を、コンソールの外から見る

`bin/rails runner` で、リポジトリを通して、ドメインのオブジェクトとして読み込めます。

```bash
bin/rails runner 'r = Ticketing::ReservationRepository.new.find(2); p [r.status, r.status_name, r.count.to_i, r.total_price.to_s, r.applicant.name]; i = Ticketing::InventoryRepository.new.find(r.event_id); p [i.capacity, i.reserved_count, i.remaining_seats, i.sales_method]'
```

```text
[:pending, "仮予約", 2, "6,000円", "初花"]
[4, 4, 0, :lottery]
```

テーブルの行（Active Record）ではなく、エンティティ・値オブジェクトとして見るのがコツです。ドメインのルール（`status_name`・`remaining_seats`）が、そのまま使えます。

### 予約の流れを、業務のイベントでたどる

業務のイベントは、`log/events_{環境}.log` に1行1件の JSON で残ります（第20章）。予約 ID でたどります。

```bash
grep '"reservation_id":2[,}]' log/events_development.log
```

```text
{"at":"2026-10-19T01:02:42.436+09:00","name":"ticketing.reservation_created","payload":{"reservation_id":2,"event_id":3,"status":"pending","occurred_at":"2026-10-19T01:02:42.349+09:00"},"tags":{},"context":{}}
```

### 整合性と、失敗した返金を調べる

```bash
bin/rails ticketing:check_inventory
```

```text
ずれはありません
```

```bash
bin/rails billing:failed_refunds
```

```text
返金に失敗した決済: 0件
```

ずれや失敗が見つかったときの直し方は、アプリの `docs/runbook.md` にあります（第20章）。

---

## F.4　よくあるエラーと、まず見るところ

| エラー・症状 | よくある原因 | まず見るところ | 章 |
|-----------|-----------|------------|----|
| `uninitialized constant Ticketing::Lottery` と `No examples found.` | まだクラスがない（テストを先に書いたとき）か、ファイル名とクラス名が合わない | `app/domain/ticketing/lottery.rb` のファイル名と `module`・`class` の名前（Zeitwerk の決まり） | 7・21 |
| ドメインのテストだけ `NoMethodError`（`blank?`・`present?`・`minutes` など） | ドメイン層で Active Support を使った | F.2 | 8・17 |
| 期限のテストが、日によって落ちる | 「今」を固定していない | `spec/support/time_helpers.rb`・ドメインに `now:` を渡しているか | 3・17 |
| `Ticketing::Reservation::InvalidTransition` | 今の状態からは、その操作ができない | 状態遷移の表（第14章）と、予約の今の状態 | 14 |
| メールが届かないテスト | ジョブが流れていない | `perform_enqueued_jobs { ... }` で包んでいるか | 12・15 |
| ドメインイベントの購読者が動かない | トランザクションがまだコミットされていない／購読の登録がない | `config/initializers/domain_events.rb` | 12 |
| `PG::NotNullViolation`・`ActiveRecord::RecordNotUnique` | データベースの制約に当たった | 制約の名前と、ドメインのルール（ルールの最後の守りが働いた） | 9・16 |
| 並行処理のテストが止まる・通らない | テストのトランザクションの中で、別のスレッドの変更が見えない | `spec/concurrency` が、トランザクションなしで動く設定になっているか | 16 |
| 依存のルールのテストが落ちる | ドメイン層やほかのコンテキストから、使ってはいけないものを使った | `spec/architecture/dependency_rules_spec.rb` のメッセージの行 | 19 |
| リクエストスペックが、急にたくさん落ちる | 中身の入れ替えで、テストの準備（ファクトリ）が合わなくなった | 落ちた例の準備の部分。席の数え方などが変わっていないか | 11 |
