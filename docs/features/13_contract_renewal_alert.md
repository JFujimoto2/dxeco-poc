# 契約更新アラート

## 概要
SaaS契約の更新期限が近づいたときに、ダッシュボードでアラート表示し、Teams通知を送信する。契約更新の見落としを防ぐ。

## ダッシュボード表示

### アラート対象
| 区分 | 条件 | バッジ色 |
|------|------|----------|
| 期限切れ | `expires_on < 今日` | 赤（danger） |
| 7日以内 | `expires_on` が7日以内 | 赤（danger） |
| 30日以内 | `expires_on` が30日以内 | 黄（warning） |

### 表示項目
| 項目 | 説明 |
|------|------|
| SaaS名 | SaaS詳細画面へのリンク |
| プラン名 | 契約プラン |
| 契約期限 | `expires_on` の日付 |
| 残日数 | 期限までの日数（期限切れの場合は「期限切れ」表示） |

## Teams通知

### ContractRenewalAlertJob
- バッチ管理画面から手動実行、またはスケジュール実行
- 期限30日以内・7日以内・期限切れの契約を検出
- Teams Webhook（`TEAMS_WEBHOOK_URL`）にアラート通知を送信
- `BatchExecutionLog` に実行結果を記録

### 通知内容
- SaaS名、プラン名、契約期限、残日数
- 対象件数のサマリ

## 技術的な仕組み
- `SaasContract` のスコープ: `expiring_within(days)`, `expired`
- `ContractRenewalAlertJob` で検出 → Teams通知
- ダッシュボードでは `DashboardController` でクエリ実行

## アクセス権限
ダッシュボードのアラートセクションは全ロールに表示。バッチ実行はadminのみ。
