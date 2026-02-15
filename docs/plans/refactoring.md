# リファクタリング計画

## テストカバレッジ現況

**実施前: Line 91.2% (784/860) / Branch 70.7% (188/266)**
**実施後: Line 95.5% (833/872) / Branch 77.9% (201/258)**

### カバレッジ低ファイル（90%未満）

| ファイル | カバレッジ | 原因 |
|----------|-----------|------|
| `app/helpers/application_helper.rb` | 53.3% (8/15) | ヘルパーメソッドの未テスト分岐 |
| `app/controllers/tasks_controller.rb` | 59.5% (25/42) | preset展開ロジックが未テスト |
| `app/controllers/approval_requests_controller.rb` | 76.1% (35/46) | approve/reject の一部パス未テスト |
| `app/jobs/contract_renewal_alert_job.rb` | 76.2% (16/21) | 通知条件の分岐が未テスト |
| `app/controllers/task_presets_controller.rb` | 80.0% (20/25) | CRUD一部パス未テスト |
| `app/jobs/entra_user_sync_job.rb` | 86.4% (19/22) | エラーハンドリング未テスト |
| `app/controllers/surveys_controller.rb` | 86.4% (57/66) | create_cleanup_task等 |
| `app/jobs/retired_account_detection_job.rb` | 89.5% (17/19) | 一部分岐未テスト |

### 100%カバレッジ（29ファイル）
モデル全13件、メーラー全4件、サービス全4件が100%。

---

## リファクタリング項目

### Priority A: コード重複の解消

#### A1. CSVエクスポートの共通化
**影響ファイル:**
- `app/controllers/saases_controller.rb:64-82`
- `app/controllers/saas_accounts_controller.rb:57-73`
- `app/controllers/admin/audit_logs_controller.rb:20-37`

**現状:** 3つのコントローラーに同じCSV生成パターン（BOM + CSV.generate + send_data）が重複。

**対策:** `CsvExportable` concern を作成し、共通パターンを抽出。
```ruby
# app/controllers/concerns/csv_exportable.rb
module CsvExportable
  def send_csv(filename:, headers:, rows:)
    csv_data = "\uFEFF" + CSV.generate { |csv|
      csv << headers
      rows.each { |row| csv << row }
    }
    send_data csv_data, filename: "#{filename}_#{Date.current}.csv",
              type: "text/csv; charset=utf-8"
  end
end
```

**工数:** 小（0.5h）

#### A2. CSVインポートサービスの基底クラス抽出
**影響ファイル:**
- `app/services/saas_import_service.rb`
- `app/services/saas_account_import_service.rb`

**現状:** CSV読み込み・エラーカウント・結果ハッシュ生成が重複。

**対策:** `BaseCsvImportService` を作成し、テンプレートメソッドパターンで共通化。

**工数:** 小（0.5h）

#### A3. インポートモーダルの共通パーシャル化
**影響ファイル:**
- `app/views/saases/_import_form.html.erb`
- `app/views/saas_accounts/_import_form.html.erb`

**現状:** ほぼ同一のBootstrapモーダルHTML。

**対策:** `app/views/shared/_csv_import_modal.html.erb` に統合し、`title`, `action`, `template_path` をパラメータ化。

**工数:** 小（0.5h）

#### A4. フォームエラー表示の共通化
**影響ファイル:**
- `app/views/saases/_form.html.erb`
- `app/views/saas_accounts/_form.html.erb`
- `app/views/approval_requests/new.html.erb`
- `app/views/tasks/new.html.erb`

**現状:** 同じエラー表示ブロックが4箇所に重複。

**対策:** `app/views/shared/_form_errors.html.erb` パーシャルを作成。

**工数:** 小（0.5h）

---

### Priority B: パフォーマンス改善

#### B1. ダッシュボードのクエリ最適化
**影響ファイル:** `app/controllers/dashboard_controller.rb`

**現状:**
- KPIカード: 8件の個別 `COUNT` クエリ
- コスト集計: 全 `SaasContract` をメモリにロードして Ruby で sum/group_by

**対策:**
1. コスト集計をSQL集約に変更:
```ruby
SaasContract.where.not(price_cents: nil)
  .sum("CASE WHEN billing_cycle = 'yearly' THEN price_cents/12 ELSE price_cents END")
```
2. カテゴリ別集計もSQLで:
```ruby
SaasContract.joins(:saas).where.not(price_cents: nil)
  .group("COALESCE(saases.category, '未分類')")
  .sum("CASE WHEN billing_cycle = 'yearly' THEN price_cents/12 ELSE price_cents END")
```

**工数:** 中（1h）

#### B2. N+1クエリの解消
**影響ファイル:**
- `app/views/saases/index.html.erb` — `saas.saas_accounts.size`（N+1）
- `app/views/users/index.html.erb` — `user.saas_accounts.size`（N+1）

**対策:**
1. コントローラーで `counter_cache` を利用、またはサブクエリで件数取得:
```ruby
@saases = Saas.left_joins(:saas_accounts)
              .select("saases.*, COUNT(saas_accounts.id) AS accounts_count")
              .group("saases.id")
```
2. ビューで `saas.accounts_count` を参照。

**工数:** 小（0.5h）

#### B3. 不足インデックスの追加
**確認が必要なカラム:**
- `audit_logs.resource_type` — フィルタで使用
- `audit_logs.user_id` — フィルタで使用
- `saas_accounts.status` — WHERE句で使用
- `users.account_enabled` — スコープで使用

**対策:** `db/migrate/xxx_add_missing_indexes.rb` でインデックス追加。

**工数:** 小（0.5h）

---

### Priority C: コントローラーの責務分離

#### C1. TasksController#new のプリセット展開ロジック抽出
**影響ファイル:** `app/controllers/tasks_controller.rb:16-51`

**現状:** 35行のプリセット展開ロジックがnewアクション内にある。

**対策:** `TaskBuilder` サービスクラスに抽出。
```ruby
class TaskBuilder
  def self.from_preset(preset, target_saas: nil)
    # プリセット展開ロジック
  end
end
```

**工数:** 中（1h）

#### C2. SurveysController#create_cleanup_task の抽出
**影響ファイル:** `app/controllers/surveys_controller.rb:64-99`

**現状:** サーベイ結果からタスク生成する複合ロジックがコントローラーに直書き。

**対策:** `SurveyCleanupTaskGenerator` サービスに抽出。

**工数:** 中（1h）

#### C3. SaasAccountsController のフィルタリング改善
**影響ファイル:** `app/controllers/saas_accounts_controller.rb:5-11`

**現状:** 手動で `if params[:xxx].present?` を繰り返すチェーン。

**対策:** モデルにフィルタスコープを追加:
```ruby
scope :filter_by_saas, ->(saas_id) { saas_id.present? ? where(saas_id: saas_id) : all }
scope :filter_by_user, ->(user_id) { user_id.present? ? where(user_id: user_id) : all }
scope :filter_by_status, ->(status) { status.present? ? where(status: status) : all }
```

**工数:** 小（0.5h）

---

### Priority D: テストカバレッジ向上

#### D1. TasksController のテスト拡充（59.5% → 90%+）
- プリセット展開のテスト追加
- SaaS選択・タスクアイテム生成のテスト
- エラーケースのテスト

**工数:** 中（1h）

#### D2. ApprovalRequestsController のテスト拡充（76.1% → 90%+）
- approve/reject のエッジケース
- 権限チェックのテスト（manager vs admin）
- メール送信のテスト

**工数:** 中（1h）

#### D3. ApplicationHelper のテスト追加（53.3% → 90%+）
- ヘルパーメソッドの単体テスト

**工数:** 小（0.5h）

#### D4. ジョブのエラーケーステスト
- `ContractRenewalAlertJob` の分岐テスト（76.2%）
- `EntraUserSyncJob` のエラーハンドリングテスト（86.4%）
- `RetiredAccountDetectionJob` の分岐テスト（89.5%）

**工数:** 中（1h）

---

### Priority E: セキュリティ・堅牢性

#### E1. ジョブのトランザクション追加
**影響ファイル:** `app/jobs/entra_account_sync_job.rb`

**現状:** アカウント停止処理がトランザクションなしで逐次実行。中断時にデータ不整合のリスク。

**対策:** `ActiveRecord::Base.transaction` で囲む、または `update_all` に変更。

**工数:** 小（0.5h）

#### E2. マジックストリングの定数化
**散在する文字列:** `"active"`, `"pending"`, `"completed"`, `"未分類"` 等

**対策:** enum値は既にモデルで定義済み。`"未分類"` 等のUI文字列をI18nまたは定数に。

**工数:** 小（0.5h）

#### E3. ジョブのエラーログ改善
**影響ファイル:**
- `app/jobs/entra_user_sync_job.rb:29-31`
- `app/jobs/entra_account_sync_job.rb`

**現状:** `rescue => e` でエラーカウントだけ増加し、エラー内容を捨てている。

**対策:** `Rails.logger.error` と `BatchExecutionLog` にエラーメッセージを記録。

**工数:** 小（0.5h）

---

## 実施優先順位

| # | 項目 | 優先度 | 工数 | 効果 | 状態 |
|---|------|--------|------|------|------|
| 1 | A1. CSVエクスポート共通化 | 高 | 0.5h | 重複90行削減 | Done |
| 2 | B1. ダッシュボードクエリ最適化 | 高 | 1h | SQL集約で高速化 | Done |
| 3 | B2. N+1解消 | 高 | 0.5h | includes追加 | Done |
| 4 | D1. TasksController テスト | 高 | 1h | 59.5%→90%+ | Done |
| 5 | A2. CSVインポート基底クラス | 中 | 0.5h | 重複40行削減 | Done |
| 6 | A3. インポートモーダル共通化 | 中 | 0.5h | 重複30行削減 | Done |
| 7 | A4. フォームエラー共通化 | 中 | 0.5h | 7箇所→共通パーシャル | Done |
| 8 | C3. フィルタスコープ化 | 中 | 0.5h | コントローラー簡素化 | Done |
| 9 | D2. ApprovalRequests テスト | 中 | 1h | 76.1%→90%+ | Done |
| 10 | D3. ApplicationHelper テスト | 低 | 0.5h | 53.3%→90%+ | Done |
| 11 | D4. ジョブテスト拡充 | 低 | 1h | 分岐カバレッジ向上 | Done |
| 12 | E1. トランザクション追加 | 低 | 0.5h | データ整合性 | Done |
| 13 | E2. マジックストリング定数化 | 低 | 0.5h | 保守性向上 | Done |
| 14 | E3. エラーログ改善 | 低 | 0.5h | 運用時のデバッグ | Done |
| 15 | B3. インデックス追加 | 低 | - | 既存で充足確認済 | Skip |
| 16 | C1. TaskBuilder抽出 | 低 | 1h | 可読性向上 | Skip |
| 17 | C2. SurveyCleanupTask抽出 | 低 | 1h | 可読性向上 | Skip |

**14/17項目完了（2項目は既存で充足 or POC規模では過剰のためスキップ）**

---

作成日: 2026年2月14日
