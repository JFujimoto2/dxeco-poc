# Phase 4: 仕上げ（Teams通知・操作ログ・デモデータ）

## Context
Phase 1〜3が完了し、コア機能（台帳・サーベイ・タスク管理・申請承認・退職者検出）は全て動作する状態。
Phase 4では残りの要件を実装し、デモ可能なPOCを完成させる:
- **操作ログ**: サイドバーで唯一無効のリンク。監査対応として重要（DXECOは有料オプション）
- **Teams通知の統合**: TeamsNotifierは作成済みで、各コントローラに統合済み
- **CSVインポート**: 260件のSaaS/アカウントの初期データ投入手段
- **デモデータの充実**: 現在12件のSaaSを30件程度に拡充

## 開発フロー（TDD）
各Stepで: テスト作成(RED) → 実装(GREEN) → リファクタリング → コミット

---

## Step 1: 操作ログ（AuditLog）

### 1.1 DB設計
```
audit_logs テーブル:
  - user_id: bigint (FK → users, nullable: バッチ実行時はnull)
  - action: string (create/update/destroy)
  - resource_type: string (Saas/SaasAccount/User/Survey/Task/ApprovalRequest)
  - resource_id: bigint
  - changes_data: jsonb (変更前後の値)
  - ip_address: string
  - created_at: datetime
```

### 1.2 モデル
- `app/models/audit_log.rb`
  - belongs_to :user, optional: true
  - validates :action, :resource_type, :resource_id, presence: true
  - scope :recent, :by_resource_type, :by_user, :by_date_range

### 1.3 Concern: Auditable
- `app/models/concerns/auditable.rb`
  - `after_create`, `after_update`, `after_destroy` コールバック
  - `Current.user` と `Current.ip_address` を利用（CurrentAttributes）
  - 対象モデルに `include Auditable` を追加

### 1.4 CurrentAttributes
- `app/models/current.rb` - `Current.user`, `Current.ip_address` を定義
- `ApplicationController` の `before_action` で設定

### 1.5 管理画面
- `Admin::AuditLogsController` (index, show)
- フィルタ付き一覧（リソース種別・ユーザー・日付範囲）
- 変更詳細（JSON diff表示）

### 成果物チェックリスト
- [x] AuditLogモデル・マイグレーション
- [x] Auditable concern
- [x] Current model + ApplicationController連携
- [x] Admin::AuditLogsController + ビュー
- [x] サイドバー・ダッシュボード更新
- [x] テスト全パス (22件)

---

## Step 2: Teams通知の統合
各コントローラにTeamsNotifier呼び出しは統合済み（Phase 3で実装完了）。

### 成果物チェックリスト
- [x] SurveysController（activate, remind）
- [x] TasksController（create）
- [x] ApprovalRequestsController（create, approve, reject）

---

## Step 3: CSVインポート

### 3.1 SaaS台帳CSVインポート
- `SaasImportService` - CSV解析 → Saas一括登録
- CSVフォーマット: `name,category,url,admin_url,description,status`
- 重複チェック・エラーレポート付き

### 3.2 アカウントCSVインポート
- `SaasAccountImportService` - CSV解析 → SaasAccount一括登録
- CSVフォーマット: `saas_name,user_email,account_email,role,status`
- SaaS名/ユーザーemail → IDルックアップ

### 3.3 UI
- SaaS一覧・アカウント一覧にCSVインポートボタン（Bootstrapモーダル）

### 成果物チェックリスト
- [x] SaasImportService
- [x] SaasAccountImportService
- [x] インポートUI（ファイルアップロード + 結果表示）
- [x] テスト全パス (8件)

---

## Step 4: デモデータの充実

### 成果物チェックリスト
- [x] SaaS 30件に拡充（一般IT 14, 不動産管理 11, バックオフィス 5）
- [x] メンバー 15名に拡充（情シス3, 営業4, 管理3, 企画3, 役員2）
- [x] アカウント 136件（全社共通SaaS + 部門別割当）
- [x] サーベイ 2件（完了1, 進行中1）
- [x] タスク 2件（完了1, 進行中1）
- [x] 承認リクエスト 4件（承認済2, 却下1, 保留1）
- [x] 操作ログ 204件（Auditable自動生成 + サンプル20件）
- [x] `rails db:seed` 正常完了

---

## 検証結果
1. `bin/rubocop` - 119 files inspected, no offenses detected
2. `bin/brakeman --no-pager` - 0 warnings
3. `bundle exec rspec` - 151 examples, 0 failures
4. `rails db:reset` → `rails db:seed` - 正常完了
