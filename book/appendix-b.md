# 付録B　Railsの標準MVCとDDDの対応表

**初花**: Railsのどの機能が、DDDのどの部品にあたるのかを一覧で見たい。

**マリゴールド**: 付録Bは、その **対応表** だよ。うめチケットでは、コアドメイン（予約）とそれ以外で使い方を変えたから、2つの列に分けて書くね。

---

## B.1　フォルダと層

| Rails のフォルダ | DDD での層 | コアドメイン（予約） | 支援サブドメイン（イベント管理） |
|---------------|-----------|-----------------|---------------------------|
| `app/controllers` | プレゼンテーション | フォームで入力を確かめ、ユースケースを呼ぶだけ | 普通の CRUD（登録のときに、予約のコンテキストの残席も作る） |
| `app/views`・`app/mailers` | プレゼンテーション | 表示だけ。期限などは表示用のメソッドから読む | 普通の ERB |
| `app/forms`（本書で追加） | プレゼンテーション | 入力の形の検証（`ReservationForm`） | 使わない |
| `app/usecases`（本書で追加） | アプリケーション | ユースケース（`Ticketing::ReserveSeats` など） | 使わない |
| `app/domain`（本書で追加） | ドメイン | エンティティ・値オブジェクト・集約・ドメインイベント | 使わない |
| `app/infrastructure`（本書で追加） | インフラ | リポジトリ・アダプター・購読者 | 使わない |
| `app/models` | インフラ（予約）／すべて（イベント管理） | 保存の入れ物 | 業務の判断もバリデーションも、ここに書く |
| `app/jobs` | インフラ（呼び出しの入口） | ユースケースを呼ぶだけ | — |
| `lib/tasks` | 運用の入口 | `ticketing:check_inventory`・`billing:retry_failed_refunds` | — |

`app/services` は使いません。何でも入る場所になりやすいので、置き場所は層で決めます（`docs/architecture.md` の決めたこと6）。

---

## B.2　Active Record の機能と、DDD での置き場所

| Rails の機能 | 普通の Rails での使い方（第2章〜第3章） | うめチケットのコアドメインでは | 章 |
|------------|-------------------------------|-------------------------|----|
| `validates`（形） | 空・形式・範囲を確かめる | フォームオブジェクト（`ReservationForm`） | 13 |
| `validate`（業務） | 残席・二重予約・受付期間を確かめる | 集約・値オブジェクト・ドメインサービス | 8・9・11 |
| `before_create` などのコールバック | 料金のコピー・無料なら確定 | `Reservation.apply`（ファクトリ）とユースケース | 11・18 |
| `after_commit` のコールバック | メールを送る | ドメインイベントの購読者 | 12 |
| `enum :status` | 状態を自由に書き換える | 保存の入れ物で値を持つだけ。遷移はエンティティの `confirm`・`cancel`・`expire` | 14 |
| `has_many`・`belongs_to` | 関連をたどる | 同じコンテキストの中だけ。コンテキストをまたぐときは ID でつなぐ | 18・19 |
| `scope` | 検索条件 | リポジトリの中（`active_exists?` など） | 10 |
| `transaction` | どこでも開く | ユースケースで開く | 11 |
| `lock` | — | `InventoryRepository#find(lock: true)` | 16 |
| ユニーク制約・CHECK 制約 | — | ドメインのルールの最後の守り（二重予約・定員超過） | 9・16 |
| `ActiveSupport::Notifications` | — | ドメインイベントの配送（`DomainEvents`） | 12 |
| `Rails.event` | — | 業務のイベントのログ（`Audit::DomainEventRecorder`） | 20 |
| Active Job | メールを後で送る | 購読者がジョブを積む。ジョブは冪等にする | 12・15 |
| `includes`・`preload` | — | 一覧画面の N+1 を防ぐ | 19 |

---

## B.3　「どこに書く？」の早見表

| 書きたいこと | 置き場所 | 例 |
|-----------|--------|----|
| 人数が1〜10人か | 値オブジェクト | `Ticketing::ReservationCount` |
| 主催者の上限を超えていないか | 値オブジェクト（主催者のルール） | `Ticketing::ReservationPolicy#ensure_count_allowed!` |
| 残席に入るか | 集約ルート | `Ticketing::Inventory#reserve` |
| 同じメールアドレスの有効な予約があるか | ドメインサービス | `Ticketing::DoubleBookingCheck` |
| 支払い期限を過ぎたか | エンティティ | `Ticketing::Reservation#confirm(now:)` |
| 申込の手順（確かめて、押さえて、保存して、知らせる） | ユースケース | `Ticketing::ReserveSeats` |
| 予約のエンティティをテーブルに保存する | リポジトリ | `Ticketing::ReservationRepository` |
| うめペイの API を呼ぶ | アダプター | `Billing::UmepayGateway` |
| 予約されたらメールを送る | 購読者とジョブ | `Notification::ReservationMailSubscriber` |
| 名前が空でないか | フォームオブジェクト | `ReservationForm` |
| 業務の誤りを HTTP のステータスにする | コントローラの concern | `DomainErrorResponses` |
| イベントの告知の入力（タイトル・会場） | Active Record のモデル | `Event` |
