# メール通知機能

## 概要
サーベイ結果に基づくアカウント削除/作成依頼や、タスクのチェックリスト対応依頼を、
対象の管理者・マネージャーに個人宛メールで通知する。

## ユースケース

### 1. サーベイ → アカウント対応依頼
```
サーベイで「利用していない」回答を検出
  → 管理者がタスクを作成（退職処理・アカウント削除等）
  → タスクアイテムのアサイン先（assignee）にメール通知
    件名: 「[SaaS管理] アカウント削除のお願い: 〇〇さん / Slack」
    本文: タスク名、対象ユーザー、対象SaaS、期限、タスクURL
```

### 2. タスクアイテムのアサイン通知
```
管理者がタスクを作成し、各チェックリスト項目に担当者をアサイン
  → アサインされた担当者にメール通知
    件名: 「[SaaS管理] タスク対応のお願い: 退職処理 - 田中太郎」
    本文: タスク名、担当チェック項目一覧、期限、タスクURL
```

### 3. 承認申請の通知
```
ユーザーがSaaS利用申請を提出
  → admin/manager にメール通知（既存のTeams通知に加えて）
    件名: 「[SaaS管理] 承認依頼: Notion 新規導入」
    本文: 申請者、種別、対象SaaS、理由、申請URL
```

### 4. 承認結果の通知
```
管理者が申請を承認/却下
  → 申請者にメール通知
    件名: 「[SaaS管理] 申請が承認されました: Notion」
    本文: 対象SaaS、承認者、（却下の場合は理由）、申請URL
```

## 通知一覧

| トリガー | To（宛先） | CC | 件名プレフィックス |
|----------|-----------|-----|-------------------|
| タスク作成（アイテムにアサイン） | アサイン先ユーザー | 対象ユーザーの部署の部長（manager）+ タスク作成者 | `[SaaS管理] タスク対応のお願い` |
| 承認申請の提出（承認者指定あり） | 指定承認者 | 他のadmin/manager（承認者・申請者除く） | `[SaaS管理] 承認依頼` |
| 承認申請の提出（承認者未指定） | admin/manager 全員 | - | `[SaaS管理] 承認依頼` |
| 申請の承認 | 申請者 | 対象SaaSのオーナー（`saas.owner`） | `[SaaS管理] 申請が承認されました` |
| 申請の却下 | 申請者 | 対象SaaSのオーナー（`saas.owner`） | `[SaaS管理] 申請が却下されました` |
| サーベイ配信 | 対象ユーザー全員 | - | `[SaaS管理] サーベイのお願い` |
| サーベイリマインド | 未回答ユーザー | - | `[SaaS管理] 【リマインド】サーベイ未回答` |

### CC ロジック

| CC対象 | 取得方法 |
|--------|---------|
| 部署の部長（manager） | `User.manager.where(department: target_user.department)` |
| タスク作成者 | `task.created_by` |
| SaaSオーナー | `saas.owner`（SaaS台帳の管理責任者） |

- CC 対象が To と重複する場合は除外する
- CC 対象が存在しない（未設定・nil）場合はスキップ

## 技術設計

### SMTP設定（環境変数）

| 変数名 | 用途 | 例 |
|--------|------|-----|
| `SMTP_ADDRESS` | SMTPサーバー | `smtp.office365.com` |
| `SMTP_PORT` | ポート | `587` |
| `SMTP_USERNAME` | ユーザー名 | `noreply@example.com` |
| `SMTP_PASSWORD` | パスワード | `xxxxxxxxxx` |
| `SMTP_DOMAIN` | HELOドメイン | `example.com` |
| `MAILER_FROM` | 送信元アドレス | `noreply@example.com` |

未設定の場合はメール通知をスキップ（Teams通知と同じパターン）。

### ファイル構成

```
app/mailers/
├── application_mailer.rb       # 既存（from アドレス更新）
├── task_mailer.rb              # タスク関連
├── approval_request_mailer.rb  # 承認申請関連
└── survey_mailer.rb            # サーベイ関連

app/views/
├── task_mailer/
│   └── assignment_notification.html.erb
├── approval_request_mailer/
│   ├── new_request.html.erb
│   ├── approved.html.erb
│   └── rejected.html.erb
└── survey_mailer/
    ├── distribution.html.erb
    └── reminder.html.erb

config/environments/
├── development.rb              # letter_opener で開発確認
└── production.rb               # SMTP設定

spec/mailers/
├── task_mailer_spec.rb
├── approval_request_mailer_spec.rb
└── survey_mailer_spec.rb
```

### 送信方式
- **非同期送信**: `deliver_later`（Solid Queue 経由）
- 送信失敗時はジョブがリトライ（Solid Queue のデフォルト動作）
- 開発環境では `letter_opener` gem で実際に送信せずブラウザ確認

### 既存コードへの変更

```ruby
# app/controllers/tasks_controller.rb（タスク作成後）
TaskMailer.assignment_notification(@task).deliver_later

# app/controllers/approval_requests_controller.rb（申請後）
ApprovalRequestMailer.new_request(@approval_request).deliver_later

# app/controllers/surveys_controller.rb（配信後）
SurveyMailer.distribution(survey).deliver_later
```

## 成果物チェックリスト

### 環境構築
- [x] `letter_opener` gem 追加（development用）
- [x] SMTP 環境変数の設定（config/environments/production.rb）
- [x] ApplicationMailer の from アドレスを環境変数化
- [x] `.env.example` に SMTP 関連変数を追加

### Mailer 実装
- [x] TaskMailer（アサイン通知 + CC: 部署manager, タスク作成者）
- [x] ApprovalRequestMailer（申請・承認・却下通知 + CC: SaaSオーナー）
- [x] SurveyMailer（配信・リマインド通知）

### ビュー（メールテンプレート）
- [x] タスクアサイン通知メール
- [x] 承認依頼メール
- [x] 承認結果メール（承認/却下）
- [x] サーベイ配信メール
- [x] サーベイリマインドメール

### コントローラー連携
- [x] TasksController に deliver_later 追加
- [x] ApprovalRequestsController に deliver_later 追加
- [x] SurveysController に deliver_later 追加

### テスト
- [x] TaskMailer spec（7テスト）
- [x] ApprovalRequestMailer spec（11テスト）
- [x] SurveyMailer spec（6テスト）
- [x] 全177テスト パス確認

### ドキュメント
- [x] docs/environment-setup.md に SMTP 設定手順を追記
- [x] docs/features/05_survey.md 更新
- [x] .env.example 更新
