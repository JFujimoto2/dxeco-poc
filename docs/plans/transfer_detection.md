# 異動者検出の自動化

## 概要

Entra ID同期時にユーザーの `department`（部署）の変更を検知し、Teams通知する機能を追加する。
現状は管理者がHRからの連絡を受けて手動でタスクを作成しているが、Entra IDの部署情報をソースとして自動検出する。

## 背景

| 現状 | 課題 |
|------|------|
| 部署変更はEntra ID同期で `department` に自動反映される | 変更の**検知**はしていない |
| 管理者がHRからの連絡を受けて「異動処理」タスクを手動作成 | 連絡漏れ・対応遅れのリスク |
| 退職者検出は `account_enabled: false` で自動化済み | 異動者だけ手動なのは非対称 |

## 方針

`RetiredAccountDetectionJob` と同じパターンで `TransferDetectionJob` を新規作成する。
**Entra ID同期のジョブチェーンに組み込み**、部署変更があればTeamsに通知する。

### 退職者検出との比較

| | 退職者検出 | 異動者検出（本計画） |
|---|---|---|
| ジョブ | `RetiredAccountDetectionJob` | `TransferDetectionJob` |
| 検出条件 | `account_enabled: false` | `department` が前回同期時から変更 |
| 通知内容 | 残存SaaSアカウント一覧 | 旧部署 → 新部署 + 保持SaaSアカウント一覧 |
| 後続アクション | 管理者が退職処理タスクを作成 | 管理者が異動処理タスクを作成 |
| 自動タスク作成 | なし | なし（通知のみ。タスク作成は管理者判断） |

---

## 実装設計

### 1. 検出ロジック

`EntraUserSyncJob` が `user.save!` する**前に**、`department` の変更を検知する。

```ruby
# EntraUserSyncJob 内での変更検知イメージ
user.assign_attributes(department: eu["department"], ...)

if user.persisted? && user.department_changed?
  transfers << {
    user_name: user.display_name,
    user_email: user.email,
    old_department: user.department_was,
    new_department: user.department
  }
end

user.save!
```

**ポイント:**
- `department_changed?` と `department_was` は ActiveModel::Dirty が提供する標準メソッド
- `save!` の前に呼ぶことで、DBへの追加クエリなしに変更を検知できる
- 新規ユーザー（`new_record?`）は異動ではないので除外

### 2. 設計の選択肢

#### 案A: EntraUserSyncJob 内で検知 → TransferDetectionJob に渡す

```
EntraUserSyncJob
  ├─ 同期処理中に department 変更を収集
  ├─ 同期完了
  ├─ RetiredAccountDetectionJob.perform_later
  └─ TransferDetectionJob.perform_later(transfers) ← 変更リストを渡す
```

**メリット:** `department_was` が使えるので追加テーブル不要
**デメリット:** EntraUserSyncJob の責務が増える

#### 案B: TransferDetectionJob で独自に検知（前回値の保存が必要）

```
EntraUserSyncJob
  ├─ 同期処理（変更なし）
  ├─ RetiredAccountDetectionJob.perform_later
  └─ TransferDetectionJob.perform_later ← 自分でDBと比較
```

**メリット:** ジョブ間が疎結合
**デメリット:** `save!` 後なので `department_was` が使えない。前回の部署を別途保存する必要がある

#### 採用: 案A

理由:
- ActiveModel::Dirty を活用でき、追加テーブル/カラム不要
- `RetiredAccountDetectionJob` も同じく EntraUserSyncJob 完了後に実行するパターン
- 変更リストをジョブの引数として渡すだけなので、責務の増加は最小限

### 3. TransferDetectionJob

```ruby
class TransferDetectionJob < ApplicationJob
  queue_as :default

  def perform(transfers)
    log = BatchExecutionLog.create!(
      job_name: self.class.name,
      status: "running",
      started_at: Time.current
    )

    # 各異動者のSaaSアカウント情報を付加
    results = transfers.map do |t|
      user = User.find_by(email: t[:user_email])
      accounts = user&.saas_accounts&.where(status: "active")&.includes(:saas)
      {
        **t,
        accounts: accounts&.map { |a| { saas_name: a.saas.name } } || []
      }
    end

    log.update!(
      status: "success",
      finished_at: Time.current,
      processed_count: results.size,
      created_count: results.size,
      error_messages: results.any? ? results.to_json : nil
    )

    if results.any?
      TeamsNotifier.notify(
        title: "異動者検出: #{results.size}名",
        body: format_notification(results),
        level: :info,
        link: "#{ENV.fetch('APP_URL', 'http://localhost:3000')}/admin/batches"
      )
    end
  rescue => e
    log&.update!(status: "failure", finished_at: Time.current, error_messages: e.message)
    raise
  end

  private

  def format_notification(results)
    results.map { |r|
      lines = ["#{r[:user_name]} (#{r[:user_email]})"]
      lines << "  部署: #{r[:old_department] || '(未設定)'} → #{r[:new_department] || '(未設定)'}'"
      if r[:accounts].any?
        lines << "  保持SaaS: #{r[:accounts].map { |a| a[:saas_name] }.join(', ')}"
      end
      lines.join("\n")
    }.join("\n\n")
  end
end
```

### 4. EntraUserSyncJob の変更

```ruby
class EntraUserSyncJob < ApplicationJob
  # ... 既存コード ...

  def perform
    log = BatchExecutionLog.create!(...)
    stats = { processed_count: 0, created_count: 0, updated_count: 0, error_count: 0 }
    transfers = []  # ← 追加

    # ... Entra ID からユーザー取得 ...

    entra_users.each do |eu|
      # ... 既存の assign_attributes ...

      # ← 追加: 部署変更の検知（save前に呼ぶ）
      if user.persisted? && user.department_changed? && user.account_enabled?
        transfers << {
          user_name: user.display_name,
          user_email: user.email,
          old_department: user.department_was,
          new_department: user.department
        }
      end

      user.save!
      # ... 既存の stats 更新 ...
    end

    log.update!(status: "success", ...)
    RetiredAccountDetectionJob.perform_later
    TransferDetectionJob.perform_later(transfers) if transfers.any?  # ← 追加
  rescue => e
    # ... 既存のエラーハンドリング ...
  end
end
```

### 5. 通知フォーマット

```
異動者検出: 2名

田中太郎 (tanaka@example.com)
  部署: 営業部 → マーケティング部
  保持SaaS: Salesforce, Slack, Zoom

鈴木花子 (suzuki@example.com)
  部署: 総務部 → 人事部
  保持SaaS: freee, Slack
```

### 6. 管理画面（手動実行）

管理画面のバッチ一覧に手動実行ボタンは**追加しない**。

理由:
- 異動検出は Entra ID 同期時の差分比較なので、単独実行しても意味がない
- 「Entra IDユーザー同期」ボタンを押せば自動的に検出される
- `BatchExecutionLog` には `TransferDetectionJob` の実行結果が記録されるので、結果確認は既存UIで可能

### 7. 除外条件

以下のケースは通知しない:

| ケース | 理由 |
|--------|------|
| 新規ユーザー（`new_record?`） | 異動ではなく新規登録 |
| `account_enabled: false` | 退職者は退職者検出の管轄 |
| `department` が `nil` → `nil` | 変更なし |
| `department` が `nil` → 値あり | 初回設定であり異動ではない（※ 要検討） |

> ※ `nil` → 値ありは、Entra ID側で初めて部署が設定されたケース。異動通知としてはノイズになるため除外を推奨。要検討のため実装時に確認する。

---

## ジョブチェーン（変更後）

```
EntraUserSyncJob
  ├─ Entra ID からユーザー情報を取得・同期
  ├─ 同期中に department 変更を収集
  ├─ BatchExecutionLog に記録
  ├─ RetiredAccountDetectionJob.perform_later（既存）
  └─ TransferDetectionJob.perform_later(transfers)（新規、変更がある場合のみ）
```

月次バッチ（毎月1日 6:00）で自動実行される流れは変わらない。

---

## 影響範囲

| ファイル | 変更内容 |
|----------|---------|
| `app/jobs/transfer_detection_job.rb` | 新規作成 |
| `app/jobs/entra_user_sync_job.rb` | 部署変更収集 + ジョブチェーン追加 |
| `spec/jobs/transfer_detection_job_spec.rb` | 新規作成 |
| `spec/jobs/entra_user_sync_job_spec.rb` | 部署変更検知のテスト追加 |

変更しないもの:
- DB スキーマ（追加カラム/テーブル不要）
- `TeamsNotifier`（既存の `notify` メソッドをそのまま使用）
- 管理画面（手動実行ボタン追加なし）
- ルーティング

---

## 成果物チェックリスト

### テスト（RED）
- [ ] `TransferDetectionJob` のテスト作成
  - [ ] 異動者がいる場合の通知テスト
  - [ ] 異動者がいない場合（空配列）のテスト
  - [ ] `BatchExecutionLog` 記録のテスト
  - [ ] 通知フォーマットのテスト
- [ ] `EntraUserSyncJob` のテスト追加
  - [ ] 部署変更時に `TransferDetectionJob` がキューされるテスト
  - [ ] 部署変更なし時にキューされないテスト
  - [ ] 新規ユーザーは検出対象外のテスト
  - [ ] 退職者（`account_enabled: false`）は検出対象外のテスト

### 実装（GREEN）
- [ ] `TransferDetectionJob` 実装
- [ ] `EntraUserSyncJob` に部署変更検知ロジック追加

### リファクタリング
- [ ] コードレビュー・改善

### ドキュメント
- [ ] `docs/features/08_batch_management.md` 更新
- [ ] `docs/guides/user-guide.md` の異動処理フロー更新

---

作成日: 2026年3月11日
