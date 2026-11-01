# ume_tickets — サクサクRuby on Railsでドメイン駆動設計（DDD）のサンプルアプリ

「サクサクRuby on Railsでドメイン駆動設計（DDD）」で作る、イベント予約・チケット販売サービス **「うめチケット」** のソースコードです。うめチケットは本書用の架空のサービスです。

最初は普通の Rails アプリとして作り、業務ルールが増えて Fat Model になったところで、DDD の考え方で設計し直していきます。章ごとにタグを付けてあるので、本と同じ順にコードの変化をたどれます。

## 必要なもの

| | バージョン |
|---|---|
| Ruby | 4.0.7（`.ruby-version`） |
| Rails | 8.1.4 |
| PostgreSQL | 18（Docker の `postgres:18`） |
| Docker | `docker compose` が使えること |

## 動かす

```bash
cd sakusaku-rails-ddd
bundle install
docker compose up -d        # PostgreSQL を起動する
bin/rails db:prepare
bin/rails db:seed           # 画面で試すためのイベントを登録する
bin/dev                     # http://localhost:3000
```

テスト:

```bash
bundle exec rspec               # すべてのテスト
bundle exec rspec spec/domain   # ドメイン層だけ（Rails を読み込まない）
bin/ci                          # RuboCop・セキュリティの確認・テスト
```

終わったら `docker compose down` で PostgreSQL を止めます（`-v` を付けるとデータも消えます）。

決済は、開発とテストでは手元で動く偽物の窓口（`FakePaymentGateway`）を使うので、外部のサービスやキーは要りません。

## 章ごとの状態を見る

各章の終わりにタグ `ch01`〜`ch21` があります。

```bash
git switch --detach ch08       # 第8章の終わりの状態
git switch main                # 最新に戻る
git diff --stat ch17 ch18      # 第18章で変えたファイル
```

| タグ | 章 |
|---|---|
| `ch01` | ハンズオンの準備とアプリケーションの全体像 |
| `ch02` | まずは普通のRailsアプリを作る |
| `ch03` | Fat Modelと複雑化するビジネスロジック |
| `ch04` | ドメインとユビキタス言語 |
| `ch05` | サブドメインを見つける |
| `ch06` | 境界づけられたコンテキスト |
| `ch07` | RailsでDDDを実践するための設計方針 |
| `ch08` | エンティティと値オブジェクト |
| `ch09` | 集約と集約ルート |
| `ch10` | リポジトリと永続化 |
| `ch11` | ドメインサービスとアプリケーションサービス |
| `ch12` | ドメインイベント |
| `ch13` | コントローラとドメインモデルを接続する |
| `ch14` | キャンセル・返金・状態遷移 |
| `ch15` | 外部サービス・バックグラウンドジョブとの連携 |
| `ch16` | 並行処理とデータ整合性 |
| `ch17` | DDDに適したテスト戦略 |
| `ch18` | よくあるアンチパターンを直す |
| `ch19` | Railsらしさを損なわない実践的なアーキテクチャ |
| `ch20` | ログ・監視・本番運用 |
| `ch21` | 最終演習：要件追加とドメインモデルの進化 |

付録Hの演習問題の解答例は、`ch21` から分けたブランチ `exercises` にあります（タグ `appendix-h-1`・`appendix-h`）。

## ディレクトリ構成（完成版）

| パス | 内容 |
|---|---|
| `app/domain/` | ドメイン層。Rails に依存しない Ruby のクラス（値オブジェクト・集約・ドメインイベントなど） |
| `app/usecases/` | アプリケーションサービス（`Ticketing::ReserveSeats` など） |
| `app/infrastructure/` | リポジトリ・決済の窓口・通知・監査ログなど、外の世界とつなぐ部分 |
| `app/models/` | Active Record のモデル（永続化に使う） |
| `app/controllers/`・`app/forms/`・`app/views/` | 画面と API |
| `docs/domain/` | 用語集・業務ルール一覧・サブドメイン・コンテキストマップ |
| `docs/adr/` | 設計判断の記録（ADR） |
| `docs/architecture.md`・`docs/testing.md`・`docs/runbook.md` | 層の構成・テストの方針・運用の手順 |

## 注意

- 学習用のサンプルです。本番での利用は想定していません。
- 決済サービス「うめペイ」（`https://api.umepay.example`）も架空のサービスです。
- `config/credentials.yml.enc` を復号する `config/master.key` は含めていません。本番の設定を試すときは、`config/credentials.yml.enc` を消してから `bin/rails credentials:edit` で作り直してください。
