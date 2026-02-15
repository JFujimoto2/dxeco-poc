# サーベイ → タスク連携

## 概要

サーベイの「利用なし」回答から不要アカウント削除タスクをワンクリックで生成する。
サーベイ → 検出 → タスク → 完了の一気通貫フローを実現。

## 前提

- サーベイ詳細画面（admin）に回答一覧テーブルが既に存在
- `survey_responses.not_using` スコープで「利用なし」回答を取得可能
- タスク管理機能（Task + TaskItem）が整備済み
- TeamsNotifier、TaskMailer が利用可能

## 実装計画

### 1. Task モデルに `account_cleanup` タイプを追加

- **ファイル**: `app/models/task.rb`
  - `enum :task_type` に `account_cleanup: "account_cleanup"` を追加
  - `target_user` を `optional: true` に変更（クリーンアップは特定ユーザー対象ではない場合がある）

### 2. サーベイ詳細画面に「不要アカウント一覧」セクションを追加

- **ファイル**: `app/views/surveys/show.html.erb`
  - 管理者ビューの回答一覧テーブルの下に新セクションを追加
  - `not_using` 回答のみをユーザー別にグループ表示
  - 「削除タスクを生成」ボタンを配置
  - 該当なし（0件）の場合は非表示

### 3. サーベイコントローラーに `create_cleanup_task` アクションを追加

- **ファイル**: `app/controllers/surveys_controller.rb`
  - `POST /surveys/:id/create_cleanup_task`
  - `not_using` 回答からTaskを1件生成（task_type: `account_cleanup`）
  - 各not_using回答に対してTaskItem（action_type: `account_delete`）を生成
  - TaskMailer + TeamsNotifier で通知
  - 生成済みの場合は再生成しない（重複防止）

### 4. ルーティング追加

- **ファイル**: `config/routes.rb`
  - `post :create_cleanup_task` を surveys の member に追加

### 5. テスト

#### モデルスペック
- **ファイル**: `spec/models/task_spec.rb`（既存に追加 or 新規）
  - `account_cleanup` タイプの確認

#### リクエストスペック
- **ファイル**: `spec/requests/surveys_spec.rb` に追加
  - `POST /surveys/:id/create_cleanup_task` で削除タスクが生成される
  - `not_using` 回答の数だけ TaskItem が作成される
  - 該当なしの場合はタスクが作成されない
  - viewer はアクセスできない

#### Playwright E2E
- **ファイル**: `e2e/survey-task.spec.ts`（新規）
  - サーベイ詳細画面に「不要アカウント」セクションが表示される
  - 「削除タスクを生成」ボタンが表示される

## 成果物チェックリスト

- [x] Task モデルに `account_cleanup` タイプ追加
- [x] `target_user` を optional に変更（マイグレーション追加）
- [x] サーベイ詳細画面に「不要アカウント一覧」セクション追加
- [x] `create_cleanup_task` アクション実装
- [x] ルーティング更新
- [x] RSpecテスト追加（リクエスト4件）
- [x] Playwright E2Eテスト追加（`e2e/survey-task.spec.ts` — 2テスト）
- [x] Rubocop + RSpec + Playwright 全パス確認
