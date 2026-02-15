# エラー監視・アラート通知

## 概要

本番アプリのエラー・異常をリアルタイムで Teams チャネルに通知する仕組みを構築する。

## 方針

2つのレイヤーで監視する:

1. **アプリケーション層**: Rails の例外を捕捉して Teams に即時通知
2. **インフラ層**: Azure Monitor でコンテナクラッシュ・再起動を検知して通知

## 通知先

Teams エラー通知チャネル（Power Automate Webhook）:
- 環境変数: `TEAMS_WEBHOOK_ERROR_URL`

## 1. アプリケーション層（Rails 例外通知）

### 実装方法

`config/initializers/error_subscriber.rb` に ActiveSupport の ErrorReporter を使い、
未処理例外を捕捉して TeamsNotifier 経由で通知する。

### 通知対象

| イベント | 通知内容 |
|----------|---------|
| 500 Internal Server Error | エラークラス、メッセージ、URL、ユーザー |
| バックグラウンドジョブ失敗 | ジョブ名、エラー内容 |

### 通知フォーマット

```
🚨 エラー検知: RuntimeError
URL: GET /saas_accounts
ユーザー: admin@example.com
メッセージ: undefined method 'foo' for nil
発生時刻: 2026-02-15 14:30:00 JST
```

### 実装ファイル

- `app/models/error_subscriber.rb` — エラー通知サブスクライバー
- `config/initializers/error_subscriber.rb` — ErrorReporter に登録
- `app/services/teams_notifier.rb` — 既存の通知メソッドにエラー通知用を追加

### スロットリング

同一エラーの連続通知を防ぐため、Rails.cache で5分間のデバウンスを行う。

## 2. インフラ層（Azure Monitor）

### 実装方法

Azure CLI でアラートルール + Action Group（Webhook）を作成する。

### 監視対象

| メトリック | 条件 | 意味 |
|-----------|------|------|
| Replica Restart Count | > 0 / 5分 | コンテナクラッシュ・再起動 |

### 作成コマンド

```bash
# Action Group（Teams Webhook）作成
az monitor action-group create \
  --resource-group rg-dxceco-poc \
  --name ag-dxceco-error \
  --short-name dxceco-err \
  --action webhook teams-error "<TEAMS_WEBHOOK_ERROR_URL>"

# コンテナ再起動アラート
az monitor metrics alert create \
  --resource-group rg-dxceco-poc \
  --name alert-container-restart \
  --scopes <Container App Resource ID> \
  --condition "total RestartCount > 0" \
  --window-size 5m \
  --action ag-dxceco-error
```

## 3. 環境変数

| 変数名 | 用途 |
|--------|------|
| `TEAMS_WEBHOOK_ERROR_URL` | エラー通知チャネルの Webhook URL |

本番のContainer Appsに設定する。未設定時はエラー通知をスキップ（アプリ動作に影響なし）。

## 成果物チェックリスト

### アプリケーション層
- [ ] `ErrorSubscriber` クラス作成
- [ ] `TeamsNotifier.notify_error` メソッド追加
- [ ] ErrorReporter への登録（initializer）
- [ ] スロットリング（5分デバウンス）
- [ ] RSpec テスト作成
- [ ] 本番環境変数に `TEAMS_WEBHOOK_ERROR_URL` 設定

### インフラ層
- [ ] Azure Monitor Action Group 作成
- [ ] コンテナ再起動アラートルール作成

### ドキュメント
- [ ] `docs/features/` にドキュメント追加
- [ ] `インフラ構成.md` 更新

---

作成日: 2026年2月15日
