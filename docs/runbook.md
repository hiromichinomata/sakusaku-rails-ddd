# うめチケット 運用の手順書

## 予約をたどる

業務のイベントは `log/events_{環境}.log` に1行1件の JSON で残る。予約IDでたどる。

```bash
grep '"reservation_id":1[,}]' log/events_production.log
```

| イベント | 起きたこと |
|---------|---------|
| `ticketing.reservation_created` | 申込を受け付けた（仮予約・予約確定） |
| `billing.charged` | 支払い金額を受け取った（支払いID） |
| `ticketing.reservation_confirmed` | 予約確定になった |
| `ticketing.reservation_canceled` | キャンセルされた（返金する金額） |
| `ticketing.reservation_expired` | 支払い期限を過ぎて、期限切れになった |
| `billing.refunded` | 返金した（返金ID） |
| `billing.refund_failed` | 返金を5回やり直しても失敗した |
| `ticketing.inventory_mismatch` | 残席の予約済みの人数と、有効な予約の合計がずれている |

`context` の `request_id`（画面・API）や `job_class`（ジョブ）で、どこで起きたかが分かる。

## 決済サービス（うめペイ）が止まった

1. `billing.refund_failed` が増えていないかを見る
2. `bin/rails billing:failed_refunds` で、返金に失敗した決済を一覧にする
3. うめペイが直ったことを確かめてから、`bin/rails billing:retry_failed_refunds` で積み直す
4. もう一度 `bin/rails billing:failed_refunds` を流し、0件になったことを確かめる

同じ冪等キーで頼むので、積み直しても二重に返金されない。

## 残席がずれた

1. `bin/rails ticketing:check_inventory` で、ずれているイベントを一覧にする
2. 予約IDでログをたどり、ユースケースを通らずに変わった予約を探す（コンソールでの書き換えなど）
3. 直し方を決めてから、残席か予約のどちらかを直す。直したら、もう一度 `ticketing:check_inventory` を流す

## 失敗したジョブ

```bash
bin/rails runner 'SolidQueue::FailedExecution.order(:id).each { |f| puts [f.job.class_name, f.job.arguments["arguments"].inspect, f.exception_class, f.message].join(" / ") }'
```

- 直せば通るもの（外部サービスの一時的な障害）は、原因が直ってから `retry`
- 何度やっても通らないもの（存在しない予約など）は、原因を記録してから `discard`
