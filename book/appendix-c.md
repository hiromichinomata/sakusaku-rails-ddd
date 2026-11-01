# 付録C　サンプルアプリのディレクトリ構成一覧

**初花**: 完成したうめチケットの、どこに何があるかを一覧で見たい。

**マリゴールド**: 付録Cは、第21章を終えたときの **フォルダの地図** だよ。`tree` の出力に、ファイルごとの役割と、出てきた章を書き足したよ。

---

## C.1　`app`

`tree app` の出力です（`assets`・`javascript`・`helpers`・`views/layouts`・`views/pwa` は、Rails が作ったままなので省きました）。右の `#` からあとは、説明のために書き足したものです。

```text
app
├── controllers                         # プレゼンテーション層
│   ├── api
│   │   ├── base_controller.rb          # API の共通の入口（第13章）
│   │   └── reservations_controller.rb  # 予約の API（第13章・第16章）
│   ├── application_controller.rb
│   ├── concerns
│   │   ├── domain_error_responses.rb   # 業務の誤り → HTTP のステータス（第13章）
│   │   └── idempotent_request.rb       # Idempotency-Key（第16章）
│   ├── events_controller.rb            # イベント管理。普通の CRUD（第2章）
│   ├── home_controller.rb
│   ├── payments_controller.rb          # 支払い（第3章・第15章）
│   └── reservations_controller.rb      # 申込・キャンセル（第13章・第14章）
├── domain                              # ドメイン層。Rails を読み込まずに動く
│   ├── email_address.rb                # 値オブジェクト（第8章）
│   ├── money.rb                        # 値オブジェクト（第8章）
│   └── ticketing                       # 予約のコンテキスト（コアドメイン）
│       ├── applicant.rb                # 申込者（第8章）
│       ├── business_rule_violation.rb  # 業務の誤りの親クラス（第9章）
│       ├── cancellation_deadline.rb    # 返金期限（第14章・第21章）
│       ├── double_booking_check.rb     # ドメインサービス（第11章）
│       ├── inventory.rb                # 残席の集約（第9章・第21章）
│       ├── lottery.rb                  # 抽選（第21章）
│       ├── not_found.rb
│       ├── reservation_canceled.rb     # ドメインイベント（第14章）
│       ├── reservation_confirmed.rb    # ドメインイベント（第12章）
│       ├── reservation_count.rb        # 予約の人数（第8章・第21章）
│       ├── reservation_created.rb      # ドメインイベント（第12章）
│       ├── reservation_expired.rb      # ドメインイベント（第20章）
│       ├── reservation_policy.rb       # 主催者のルール（第21章）
│       ├── reservation.rb              # 予約のエンティティ（第8章・第14章）
│       ├── sales_info.rb               # 予約から見たイベント（第11章）
│       ├── sales_period.rb             # 受付期間（第11章）
│       └── waitlist.rb                 # キャンセル待ち（第21章）
├── forms
│   └── reservation_form.rb             # 入力の形の検証（第13章）
├── infrastructure                      # インフラ層
│   ├── audit
│   │   └── domain_event_recorder.rb    # 業務のイベントのログ（第20章）
│   ├── billing                         # 決済のコンテキスト
│   │   ├── card_declined.rb
│   │   ├── fake_payment_gateway.rb     # 偽物の決済の窓口（第3章・第15章）
│   │   ├── gateway_unavailable.rb
│   │   ├── refund_subscriber.rb        # キャンセル → 返金のジョブ（第14章）
│   │   └── umepay_gateway.rb           # うめペイのアダプター（第15章）
│   ├── billing.rb                      # 環境ごとに窓口を選ぶ（第15章）
│   ├── domain_events.rb                # ドメインイベントの配送（第12章）
│   ├── notification                    # 通知のコンテキスト
│   │   └── reservation_mail_subscriber.rb  # イベント → メールのジョブ（第12章）
│   └── ticketing
│       ├── inventory_consistency_check.rb  # 残席のずれを調べる（第20章）
│       ├── inventory_repository.rb     # リポジトリ（第10章・第16章）
│       ├── lottery_entry_repository.rb # 抽選の申込（第21章）
│       ├── reservation_repository.rb   # リポジトリ（第10章）
│       ├── sales_info_reader.rb        # イベント管理からの読み替え（第11章・第21章）
│       ├── waitlist_entry_repository.rb  # キャンセル待ち（第21章）
│       └── waitlist_subscriber.rb      # 席が戻った → 案内のジョブ（第21章）
├── jobs                                # ユースケースを呼ぶだけ
│   ├── application_job.rb
│   ├── billing
│   │   └── refund_payment_job.rb       # 返金（第14章・第15章）
│   ├── check_inventory_consistency_job.rb  # 1時間ごとの整合性チェック（第20章）
│   ├── expire_pending_reservations_job.rb  # 支払い期限切れ（第3章・第14章）
│   ├── notification
│   │   └── send_reservation_mail_job.rb    # メール（第12章・第15章）
│   └── ticketing
│       └── offer_released_seats_job.rb     # キャンセル待ちへの案内（第21章）
├── mailers
│   ├── application_mailer.rb
│   └── reservation_mailer.rb
├── models                              # Active Record。予約では保存の入れ物
│   ├── application_record.rb
│   ├── concerns
│   ├── event.rb                        # イベント管理のモデル（業務の判断もここ）
│   ├── idempotency_key.rb              # 第16章
│   ├── lottery_entry.rb                # 第21章
│   ├── organizer.rb                    # イベント管理のモデル（第21章）
│   ├── payment.rb                      # 決済の記録（第14章・第18章）
│   ├── reservation.rb                  # 予約の保存の入れ物
│   ├── ticket_inventory.rb             # 残席の保存の入れ物（第9章）
│   └── waitlist_entry.rb               # 第21章
├── usecases                            # アプリケーション層
│   ├── billing
│   │   ├── charge_reservation.rb       # 支払いを受け取る（第18章）
│   │   └── retry_failed_refunds.rb     # 返金のやり直し（第20章）
│   └── ticketing
│       ├── allocate_seats.rb           # 席を押さえて予約を作る部品（第21章）
│       ├── cancel_reservation.rb       # キャンセル（第14章）
│       ├── confirm_reservation.rb      # 確定（第14章）
│       ├── draw_lottery.rb             # 抽選する（第21章）
│       ├── enter_lottery.rb            # 抽選に申し込む（第21章）
│       ├── expire_reservation.rb       # 期限切れにする（第14章）
│       ├── join_waitlist.rb            # キャンセル待ちに登録する（第21章）
│       ├── offer_released_seats.rb     # 戻った席を案内する（第21章）
│       ├── pay_for_reservation.rb      # 支払う（第15章）
│       └── reserve_seats.rb            # 申し込む（第11章）
└── views
    ├── events
    │   ├── index.html.erb
    │   ├── new.html.erb
    │   └── show.html.erb
    ├── home
    │   └── index.html.erb
    ├── reservation_mailer
    │   ├── confirmed.text.erb
    │   └── payment_request.text.erb
    ├── reservations
    │   └── show.html.erb
    └── shared
        └── _errors.html.erb
```

---

## C.2　`spec`

フォルダは、`docs/testing.md` の「層ごとのテスト」の表と同じ分け方です。

```text
spec
├── architecture        # 依存のルール（第19章）
├── concurrency         # 同時の申込（第16章）。--tag concurrency
├── domain              # Rails なし。domain_helper を読み込む（第8章〜）
│   └── ticketing
├── domain_helper.rb    # app/domain だけを読み込む（第8章）
├── factories           # FactoryBot
├── forms               # 入力の形（第13章）
├── infrastructure      # リポジトリ・アダプター・契約テスト・購読者
├── jobs                # やり直し・冪等（第15章）
├── models              # データベースの制約
├── operations          # 障害の演習（第20章）
├── rails_helper.rb
├── requests            # 利用者から見た振る舞い（第2章〜。安全網）
├── setup               # 環境の確認（第1章）
├── spec_helper.rb
├── support             # 時計の固定・メール・決済の窓口・SQL の数・WebMock
└── usecases            # 部品のつながり（本物のデータベース）
```

---

## C.3　`docs` とそのほか

```text
docs
├── adr                       # 設計の判断の記録（第21章）
│   ├── 0001-lottery-as-separate-aggregate.md
│   ├── 0002-waitlist-through-domain-events.md
│   └── 0003-organizer-reservation-policy.md
├── architecture.md           # 層・決めたこと・やらないこと（第7章・第19章）
├── domain
│   ├── context_map.md        # コンテキストマップ（第6章）
│   ├── glossary.md           # 用語集（第4章〜第21章）
│   ├── rules.md              # 業務ルール R-01〜R-14（第4章〜第21章）
│   └── subdomains.md         # サブドメイン分類表（第5章・第21章）
├── issues_before_ddd.md      # DDDを適用する前の課題一覧（第3章〜第20章）
├── runbook.md                # 運用の手順書（第20章）
└── testing.md                # テストの方針（第17章）
```

| ファイル | 役割 | 章 |
|--------|------|----|
| `config/initializers/domain_events.rb` | ドメインイベントの購読者の登録 | 12・14・21 |
| `config/initializers/event_log.rb` | 業務のイベントを `log/events_{環境}.log` に書く | 20 |
| `config/ci.rb` | `bin/ci` の段階（スタイル・セキュリティ・ドメインのテスト・全部のテスト） | 17 |
| `config/recurring.yml` | 期限切れ・整合性チェックの定期実行（Solid Queue） | 14・20 |
| `lib/tasks/ticketing.rake` | `ticketing:check_inventory` | 20 |
| `lib/tasks/billing.rake` | `billing:failed_refunds`・`billing:retry_failed_refunds` | 20 |
