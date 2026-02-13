# 契約更新アラート

## 概要

SaaS契約の更新期限が近い（30日以内）ものをダッシュボードに表示し、期限前にTeams通知を送信する。
期限切れ契約も一覧で確認できるようにする。

## 前提

- `saas_contracts.expires_on` カラム（date型）が既に存在
- `TeamsNotifier.notify` が整備済み
- Solid Queue（`perform_later`）が利用可能
- seedデータでは `rand(3..12).months.from_now` で期限が設定される

## 実装計画

### 1. SaasContract モデルにスコープ追加

- **ファイル**: `app/models/saas_contract.rb`
- `scope :expiring_soon, ->(days = 30)` — expires_on が今日〜N日後の契約
- `scope :expired` — expires_on が過去（期限切れ）
- `scope :expiring_within, ->(days)` — 指定日数以内に期限切れ

### 2. ダッシュボードに「更新期限が近い契約」カードを追加

- **ファイル**: `app/controllers/dashboard_controller.rb`
  - `@expiring_contracts` — 30日以内に期限が来る契約（SaaS名含むjoins）
  - `@expired_contracts_count` — 期限切れ契約数
- **ファイル**: `app/views/dashboard/index.html.erb`
  - 既存カード行の下に「契約更新アラート」セクションを追加
  - 期限切れ件数 + 30日以内の更新予定をテーブル表示（SaaS名、プラン、期限日、残日数）
  - 0件の場合は非表示

### 3. 契約更新通知ジョブ

- **ファイル**: `app/jobs/contract_renewal_alert_job.rb`
  - 30日前・7日前の契約を検出してTeams通知を送信
  - `BatchExecutionLog` に実行記録を残す（既存パターン踏襲）
  - APP_URLを使ったSaaS詳細ページへのリンク付き

### 4. バッチ管理画面からの手動実行

- **ファイル**: `app/controllers/admin/batches_controller.rb`
  - `check_contract_renewals` アクションを追加
- **ファイル**: `config/routes.rb`
  - `post :check_contract_renewals` をbatchesのcollectionに追加
- **ファイル**: `app/views/admin/batches/index.html.erb`
  - 「契約更新チェック」ボタンを追加

### 5. seedデータの調整

- **ファイル**: `db/seeds.rb`
  - 一部の契約に「7日以内」「30日以内」「期限切れ」の期限を設定
  - デモ時にダッシュボードのアラートが確認できるようにする

### 6. テスト

#### モデルスペック
- **ファイル**: `spec/models/saas_contract_spec.rb` に追加
  - `expiring_soon` スコープ: 30日以内の契約のみ返す
  - `expired` スコープ: 期限切れ契約のみ返す
  - 期限なし（nil）の契約は含まれないことを確認

#### リクエストスペック
- **ファイル**: `spec/requests/dashboard_spec.rb` に追加
  - ダッシュボードに期限切れ契約が表示される
  - 30日以内の更新予定が表示される

#### ジョブスペック
- **ファイル**: `spec/jobs/contract_renewal_alert_job_spec.rb`（新規）
  - 30日以内の契約があればTeams通知を送信
  - 該当なしなら通知しない
  - BatchExecutionLogが記録される

#### Playwright E2E
- **ファイル**: `e2e/csv-import.spec.ts` と同様の構成で `e2e/contract-alert.spec.ts`
  - ダッシュボードに「契約更新」セクションが表示される

## 成果物チェックリスト

- [x] SaasContract にスコープ追加（expiring_soon, expired）
- [x] ダッシュボードに「更新期限が近い契約」カード追加
- [x] ContractRenewalAlertJob 作成
- [x] バッチ管理画面に手動実行ボタン追加
- [x] ルーティング更新
- [x] seedデータ調整（デモ用の期限設定）
- [x] モデルスペック追加
- [x] リクエストスペック追加
- [x] ジョブスペック追加
- [x] Playwright E2Eテスト追加
- [x] Rubocop + RSpec + Playwright 全パス確認
