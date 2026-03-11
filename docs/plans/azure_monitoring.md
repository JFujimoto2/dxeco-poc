# Azure Monitor 監視設計

## 概要

AWSのCloudWatch相当の監視基盤をAzure Monitor + Log Analyticsで構築する。
サーバーの異常検知・ログの一元管理・アラート通知を実現し、障害発生時に振り返りができる環境を整備する。

## 背景・課題

現状の監視は以下の課題がある:

| 現状 | 課題 |
|------|------|
| `ErrorSubscriber` → Teams通知 | DBに残らない。過去のエラーを振り返れない |
| Railsログ（`log/`） | コンテナ再起動で消失。構造化されていない |
| バッチ実行ログ（DB） | ジョブ統計のみ。詳細なエラートレースがない |
| インフラ監視 | 未構築。CPU/メモリ/再起動を検知できない |

## 方針

**Azure Monitor + Log Analytics** を中心に、3層の監視を構築する:

1. **ログ集約** — コンテナログ（stdout/stderr）をLog Analyticsに自動収集
2. **メトリクス監視** — CPU/メモリ/再起動/リクエスト数をリアルタイム監視
3. **アラート通知** — 閾値超過時にTeamsへ自動通知

```
                    ┌──────────────────────┐
                    │   Azure Monitor      │
                    │                      │
┌──────────┐       │  ┌────────────────┐  │       ┌──────────┐
│ Container│──────▶│  │ Log Analytics  │  │──────▶│  Teams   │
│ Apps     │ ログ  │  │ ワークスペース   │  │ Alert  │  通知    │
│          │──────▶│  └────────────────┘  │       └──────────┘
│ Rails    │メトリ │  ┌────────────────┐  │
│          │クス   │  │ メトリクス       │  │
└──────────┘       │  └────────────────┘  │
                    └──────────────────────┘

アプリ層（既存）:
┌──────────┐       ┌──────────────────┐       ┌──────────┐
│ Rails    │──────▶│ ErrorSubscriber  │──────▶│  Teams   │
│ 例外     │       │ (5分スロットリング) │       │  通知    │
└──────────┘       └──────────────────┘       └──────────┘
```

## CloudWatch との対応表

| AWS CloudWatch | Azure 相当 | 本プロジェクトでの用途 |
|---|---|---|
| CloudWatch Logs | **Log Analytics** | Railsログ（stdout/stderr）の集約・検索 |
| CloudWatch Metrics | **Azure Monitor Metrics** | CPU/メモリ/リクエスト数の監視 |
| CloudWatch Alarms | **Azure Monitor Alert Rules** | 閾値超過時のTeams通知 |
| CloudWatch Log Insights | **KQL（Kusto Query Language）** | ログの検索・分析クエリ |
| X-Ray | Application Insights（任意） | リクエストトレース（POCでは不要） |
| CloudWatch Dashboard | **Azure Monitor Dashboard** | メトリクスの可視化（任意） |

---

## 1. Log Analytics ワークスペース

### 概要

コンテナのstdout/stderr（= Railsログ）を自動収集し、最大30日間保持する。
Azure Portalまたは KQL クエリで過去のログを検索・分析できる。

### 作成コマンド

```bash
# Log Analytics ワークスペース作成
az monitor log-analytics workspace create \
  --resource-group rg-dxceco-poc \
  --workspace-name log-dxceco-poc \
  --location japaneast \
  --retention-in-days 30
```

### 保持期間

| 設定 | 値 | 理由 |
|------|-----|------|
| 保持期間 | 30日 | 無料枠内。月次バッチサイクルをカバー |
| 日次上限 | 設定なし | POC規模では5GB/月の無料枠内に収まる |

### 収集対象

Container Appsの診断設定を有効にすると、以下が自動収集される:

| ログカテゴリ | テーブル名 | 内容 |
|---|---|---|
| ContainerAppConsoleLogs | `ContainerAppConsoleLogs_CL` | Rails stdout/stderr（アプリログ） |
| ContainerAppSystemLogs | `ContainerAppSystemLogs_CL` | コンテナランタイムのシステムログ |

### 診断設定の作成

```bash
# Container App のリソースIDを取得
CONTAINER_APP_ID=$(az containerapp show \
  --name app-dxceco-poc \
  --resource-group rg-dxceco-poc \
  --query id -o tsv)

# Log Analytics ワークスペースIDを取得
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group rg-dxceco-poc \
  --workspace-name log-dxceco-poc \
  --query id -o tsv)

# 診断設定を作成（ログ + メトリクスをLog Analyticsに送信）
az monitor diagnostic-settings create \
  --name diag-dxceco \
  --resource "$CONTAINER_APP_ID" \
  --workspace "$WORKSPACE_ID" \
  --logs '[
    {"category": "ContainerAppConsoleLogs", "enabled": true},
    {"category": "ContainerAppSystemLogs", "enabled": true}
  ]' \
  --metrics '[
    {"category": "AllMetrics", "enabled": true}
  ]'
```

---

## 2. Railsログの構造化出力

Log Analyticsで効率的に検索するため、RailsログをJSON形式で出力する。

### 設定

`config/environments/production.rb` に以下を追加:

```ruby
# 構造化ログ（JSON形式）— Log Analytics での検索性を向上
config.rails_semantic_logger.format = :json if defined?(SemanticLogger)

# 標準のRailsロガーでもJSON出力可能（semantic_logger未使用時）
config.log_formatter = ::Logger::Formatter.new
config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
```

> **注:** 現状のRails標準ロガーでもLog Analyticsは動作する。JSON構造化は検索性向上のための任意改善。

---

## 3. メトリクス監視

Container Appsが自動的に収集するメトリクスを監視する。

### 監視対象メトリクス

| メトリクス | 説明 | 正常値 | アラート閾値 |
|---|---|---|---|
| `CpuPercentage` | CPU使用率 | < 30% | > 80%（5分間平均） |
| `MemoryPercentage` | メモリ使用率 | < 50% | > 80%（5分間平均） |
| `RestartCount` | コンテナ再起動回数 | 0 | > 0（5分間合計） |
| `Requests` | リクエスト数 | 変動 | 参考値として記録 |
| `ResponseTime` | レスポンスタイム | < 500ms | 参考値として記録（POC規模ではアラート不要） |

---

## 4. アラートルール

### 通知先: Action Group

Teams Webhook を通知先として設定する（`error_monitoring.md` で計画済みのものと共通）。

```bash
# Action Group 作成（Teams Webhook）
az monitor action-group create \
  --resource-group rg-dxceco-poc \
  --name ag-dxceco-error \
  --short-name dxceco-err \
  --action webhook teams-error "<TEAMS_WEBHOOK_ERROR_URL>"
```

### アラートルール一覧

| # | ルール名 | メトリクス | 条件 | 重要度 |
|---|---|---|---|---|
| 1 | alert-container-restart | RestartCount | > 0 / 5分 | Sev1（重大） |
| 2 | alert-high-cpu | CpuPercentage | > 80% / 5分平均 | Sev2（警告） |
| 3 | alert-high-memory | MemoryPercentage | > 80% / 5分平均 | Sev2（警告） |

### 作成コマンド

```bash
# 1. コンテナ再起動アラート（Sev1: 重大）
az monitor metrics alert create \
  --resource-group rg-dxceco-poc \
  --name alert-container-restart \
  --scopes "$CONTAINER_APP_ID" \
  --condition "total RestartCount > 0" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 1 \
  --description "コンテナが再起動しました。クラッシュの可能性があります。" \
  --action ag-dxceco-error

# 2. CPU使用率アラート（Sev2: 警告）
az monitor metrics alert create \
  --resource-group rg-dxceco-poc \
  --name alert-high-cpu \
  --scopes "$CONTAINER_APP_ID" \
  --condition "avg CpuPercentage > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --description "CPU使用率が80%を超えています。" \
  --action ag-dxceco-error

# 3. メモリ使用率アラート（Sev2: 警告）
az monitor metrics alert create \
  --resource-group rg-dxceco-poc \
  --name alert-high-memory \
  --scopes "$CONTAINER_APP_ID" \
  --condition "avg MemoryPercentage > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --description "メモリ使用率が80%を超えています。" \
  --action ag-dxceco-error
```

---

## 5. よく使うKQLクエリ

Log Analyticsに蓄積されたログをAzure Portal上で検索するためのクエリ例。

### エラーログの検索

```kusto
// 直近24時間のエラーログ
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(24h)
| where Log_s contains "ERROR" or Log_s contains "FATAL"
| order by TimeGenerated desc
| take 50
```

### 特定のリクエストパスのログ

```kusto
// /saas_accounts へのリクエストログ
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(1h)
| where Log_s contains "/saas_accounts"
| order by TimeGenerated desc
```

### バックグラウンドジョブの実行ログ

```kusto
// Solid Queue ジョブの実行ログ
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(7d)
| where Log_s contains "Job" or Log_s contains "SolidQueue"
| order by TimeGenerated desc
| take 100
```

### コンテナの再起動イベント

```kusto
// コンテナのシステムイベント（起動・停止・再起動）
ContainerAppSystemLogs_CL
| where TimeGenerated > ago(7d)
| where Log_s contains "restart" or Log_s contains "start" or Log_s contains "stop"
| order by TimeGenerated desc
```

### 時間帯別のエラー発生頻度

```kusto
// 1時間ごとのエラー件数推移
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(7d)
| where Log_s contains "ERROR"
| summarize ErrorCount = count() by bin(TimeGenerated, 1h)
| order by TimeGenerated asc
| render timechart
```

---

## 6. 監視の全体像（アプリ層 + インフラ層）

| レイヤー | 検知対象 | 通知先 | 振り返り |
|---|---|---|---|
| **アプリ層（実装済み）** | Rails例外（500, ジョブ失敗） | Teams（即時） | Teams履歴 + Railsログ（Log Analytics） |
| **インフラ層（本計画）** | コンテナ再起動 | Teams（即時） | Log Analytics（システムログ） |
| **インフラ層（本計画）** | CPU/メモリ高騰 | Teams（即時） | Azure Monitor メトリクス |
| **アプリ層（既存）** | 操作ログ | — | `audit_logs` テーブル（管理画面） |
| **アプリ層（既存）** | バッチ実行結果 | — | `batch_execution_logs` テーブル（管理画面） |

---

## 7. コスト

| リソース | 料金 | 備考 |
|---|---|---|
| Log Analytics データ取り込み | **無料枠: 5GB/月** | POC規模（月1回利用）なら十分 |
| Log Analytics 保持（30日） | **無料** | 31日以上は従量課金 |
| アラートルール（メトリクス） | **無料枠: 月10件** | 3件で十分 |
| Action Group（Webhook） | **無料** | — |
| **合計** | **ほぼ¥0** | 無料枠内で運用可能 |

> ※ 万が一ログ量が5GB/月を超えた場合: ¥401/GB（従量課金）。POC規模では超える可能性は極めて低い。

---

## 8. Application Insights（任意・将来検討）

現時点では不要。全社展開でリクエスト数が増えた場合に検討する。

| 機能 | CloudWatch相当 | POCでの要否 |
|---|---|---|
| リクエストトレース | X-Ray | **不要**（POC規模では過剰） |
| 依存関係マップ | ServiceLens | **不要** |
| ライブメトリクス | Real-time metrics | **不要** |
| 可用性テスト | Synthetics | **不要** |

導入する場合は `applicationinsights` gem を追加し、接続文字列を環境変数に設定するだけ。

---

## 成果物チェックリスト

### インフラ構築（Azure CLI）

- [ ] Log Analytics ワークスペース作成（`log-dxceco-poc`）
- [ ] 診断設定の作成（コンテナログ + メトリクス → Log Analytics）
- [ ] Action Group 作成（`ag-dxceco-error` — Teams Webhook）
- [ ] アラートルール: コンテナ再起動（`alert-container-restart`）
- [ ] アラートルール: CPU高騰（`alert-high-cpu`）
- [ ] アラートルール: メモリ高騰（`alert-high-memory`）

### アプリケーション（任意改善）

- [ ] Railsログの構造化出力（JSON形式）— 検索性向上

### 確認・テスト

- [ ] Log Analyticsにコンテナログが流れることを確認
- [ ] KQLクエリでログ検索できることを確認
- [ ] アラート発火 → Teams通知の動作確認

### ドキュメント

- [x] 計画書作成: `docs/plans/azure_monitoring.md`（本ドキュメント）
- [ ] `infra/インフラ構成.md` に監視セクション追記
- [ ] `docs/plans/error_monitoring.md` のインフラ層チェックリスト更新

---

作成日: 2026年3月11日
