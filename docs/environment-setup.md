# 環境変数・外部サービス接続ガイド

## 目次

- [環境変数一覧](#環境変数一覧)
- [環境別の設定方法](#環境別の設定方法)
- [Entra ID SSO の設定](#entra-id-sso-の設定)
- [Entra ID ユーザー同期（Microsoft Graph API）の設定](#entra-id-ユーザー同期microsoft-graph-apiの設定)
- [Teams Webhook 通知の設定](#teams-webhook-通知の設定)
- [PostgreSQL の設定](#postgresql-の設定)
- [接続テスト手順](#接続テスト手順)
- [IaC 向け環境変数テンプレート](#iac-向け環境変数テンプレート)

---

## 環境変数一覧

### 必須（外部サービス連携時）

| 変数名 | 用途 | 例 |
|--------|------|-----|
| `ENTRA_CLIENT_ID` | Entra ID アプリのクライアントID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `ENTRA_CLIENT_SECRET` | Entra ID アプリのクライアントシークレット | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| `ENTRA_TENANT_ID` | Entra ID のテナントID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `APP_URL` | アプリの公開URL | `https://saas-mgmt.example.com` |
| `TEAMS_WEBHOOK_URL` | Teams チャネルの Incoming Webhook URL（一般通知） | `https://xxxxx.webhook.office.com/...` |
| `TEAMS_WEBHOOK_SURVEY_URL` | サーベイ専用チャネルの Webhook URL（未設定時は `TEAMS_WEBHOOK_URL` にフォールバック） | `https://xxxxx.webhook.office.com/...` |

### メール通知（SMTP）

| 変数名 | 用途 | 例 |
|--------|------|-----|
| `SMTP_ADDRESS` | SMTPサーバー | `smtp.office365.com` |
| `SMTP_PORT` | ポート | `587` |
| `SMTP_USERNAME` | ユーザー名 | `noreply@example.com` |
| `SMTP_PASSWORD` | パスワード | `xxxxxxxxxx` |
| `SMTP_DOMAIN` | HELOドメイン | `example.com` |
| `MAILER_FROM` | 送信元アドレス | `noreply@example.com` |

SMTP 変数が未設定の場合、メール通知はスキップされる（Teams通知と同じパターン）。
開発環境では `letter_opener` gem で実際にメール送信せずブラウザで確認可能。

### オプション（インフラ）

| 変数名 | 用途 | デフォルト値 |
|--------|------|-------------|
| `DATABASE_URL` | PostgreSQL 接続URL | database.yml に従う |
| `PGPORT` | PostgreSQL ポート | `5433` |
| `DXCECO_POC_DATABASE_PASSWORD` | 本番DB パスワード | - |
| `RAILS_MAX_THREADS` | Puma スレッド数 | `3` |
| `WEB_CONCURRENCY` | Puma ワーカー数 | Puma のデフォルト |
| `PORT` | アプリのリッスンポート | `3000` |
| `RAILS_LOG_LEVEL` | ログレベル（本番） | `info` |
| `JOB_CONCURRENCY` | Solid Queue プロセス数 | `1` |
| `SOLID_QUEUE_IN_PUMA` | PumaでSolid Queueを起動 | - |

### 動作の切り替え

| 設定状態 | SSO | dev_login | ユーザー同期 | Teams通知 |
|----------|:---:|:---------:|:----------:|:---------:|
| 全て未設定 | - | ○ | - | - |
| `ENTRA_*` のみ設定 | ○ | ○（dev/testのみ） | ○ | - |
| `TEAMS_WEBHOOK_URL` も設定 | ○ | ○（dev/testのみ） | ○ | ○ |

---

## 環境別の設定方法

### 開発環境（.env ファイル）

```bash
cp .env.example .env
```

`.env` を編集:

```bash
# === Entra ID SSO ===
# 未設定の場合は dev_login フォームで開発可能
ENTRA_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ENTRA_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ENTRA_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APP_URL=http://localhost:3000

# === Teams 通知 ===
# 未設定の場合は通知がスキップされる（エラーにはならない）
TEAMS_WEBHOOK_URL=https://xxxxx.webhook.office.com/webhookb2/...

# === DB ===
# WSL環境でポートが異なる場合
# PGPORT=5433
```

`.env` は `.gitignore` に含まれておりコミットされない。

### 本番環境（IaC / 環境変数）

IaC（Terraform, AWS CDK, etc.）やコンテナオーケストレーション（ECS, Kubernetes）で設定する。
[IaC 向けテンプレート](#iac-向け環境変数テンプレート)を参照。

---

## Entra ID SSO の設定

### 前提条件

- Microsoft Entra ID（Azure AD）のテナント管理者権限
- アプリ登録の権限

### 手順

#### 1. Entra ID でアプリを登録

1. [Azure Portal](https://portal.azure.com) → **Microsoft Entra ID** → **アプリの登録** → **新規登録**
2. 以下を入力:
   - **名前**: `SaaS管理ツール`（任意）
   - **サポートされるアカウントの種類**: 「この組織ディレクトリのみに含まれるアカウント（シングルテナント）」
   - **リダイレクトURI**: `Web` → `http://localhost:3000/auth/entra_id/callback`（開発時）

#### 2. クライアントシークレットを作成

1. 登録したアプリの「証明書とシークレット」→「新しいクライアントシークレット」
2. 説明: `SaaS管理ツール`、有効期限: 任意（POCなら6ヶ月推奨）
3. 作成されたシークレットの **値** をコピー（**この画面を離れると二度と確認できない**）

#### 3. 必要な情報を取得

アプリの「概要」ページから:

| Azure Portal の項目 | 環境変数 |
|---------------------|---------|
| アプリケーション (クライアント) ID | `ENTRA_CLIENT_ID` |
| ディレクトリ (テナント) ID | `ENTRA_TENANT_ID` |
| 手順2で作成したシークレットの値 | `ENTRA_CLIENT_SECRET` |

#### 4. 環境変数を設定

```bash
# .env
ENTRA_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ENTRA_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ENTRA_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APP_URL=http://localhost:3000
```

#### 5. サーバーを再起動して確認

OmniAuth の設定はミドルウェアとして初期化時に読み込まれるため、`.env` 変更後は **`bin/dev` の再起動が必要**。

```bash
# Ctrl+C で停止後
bin/dev
```

1. http://localhost:3000/login にアクセス
2. 「Microsoft アカウントでログイン」ボタンが表示される
3. クリックして会社の Microsoft アカウントで認証
4. ダッシュボードにリダイレクトされれば成功

初回ログイン時は `viewer` ロールで自動登録される。Rails コンソールでロールを変更可能:

```ruby
User.find_by(email: "your-email@example.com").update!(role: "admin")
```

#### 6. 本番環境のリダイレクトURI追加

本番デプロイ時、Entra ID のアプリ登録に本番URLのリダイレクトURIを追加する。

```
https://saas-mgmt.example.com/auth/entra_id/callback
```

`APP_URL` も本番URLに合わせて変更する。

#### トラブルシューティング

| エラー | 原因 | 対処 |
|--------|------|------|
| `No Host Info` (RuntimeError) | OIDC クライアントがホスト情報を解決できない | `config/initializers/omniauth.rb` で `discovery: true` と `host`/`scheme`/エンドポイントが明示されているか確認 |
| `Authentication failure! invalid_credentials` | クライアントシークレットが間違っている | Azure Portal でシークレットを再作成し `.env` を更新 |
| `redirect_uri_mismatch` | リダイレクトURIが一致しない | Azure Portal のアプリ登録で `http://localhost:3000/auth/entra_id/callback` が登録されているか確認 |
| SSO ボタンが表示されない | `ENTRA_CLIENT_ID` が未設定 | `.env` に設定後、`bin/dev` を再起動 |
| ログイン後に `viewer` ロールになる | 初回ログインのデフォルト動作 | Rails コンソールで `User.find_by(email: "...").update!(role: "admin")` |

---

## Entra ID ユーザー同期（Microsoft Graph API）の設定

SSO と同じアプリ登録を使うが、追加の API アクセス許可が必要。

### 手順

#### 1. API のアクセス許可を追加

1. Azure Portal → アプリの登録 → **API のアクセス許可** → **アクセス許可の追加**
2. **Microsoft Graph** → **アプリケーションの許可** を選択
3. 以下を追加:
   - `User.Read.All`（全ユーザー情報の読み取り）
4. **「（テナント名）に管理者の同意を与えます」** をクリック

#### 2. API アクセス許可の追加（SSO ログイン時のプロフィール取得）

SSOログイン時に Graph API でユーザーの部門・役職・社員番号を自動取得するため、**委任されたアクセス許可** も追加する。

1. Azure Portal → アプリの登録 → **API のアクセス許可** → **アクセス許可の追加**
2. **Microsoft Graph** → **委任されたアクセス許可** を選択
3. `User.Read` を追加（ログインユーザー自身のプロフィール読み取り）

> **注意:** `User.Read.All`（手順1）は「アプリケーションの許可」、`User.Read`（手順2）は「委任されたアクセス許可」。両方必要。

#### 3. 動作確認

```bash
# Railsコンソールで接続テスト
rails console

token = EntraClient.fetch_app_token
puts token.present? ? "トークン取得成功" : "トークン取得失敗"

users = EntraClient.fetch_all_users(token)
puts "取得ユーザー数: #{users.count}"
puts users.first&.slice("displayName", "mail", "department")
```

#### 5. バッチ管理画面から同期実行

1. 管理者でログイン
2. サイドバー「バッチ管理」
3. 「Entra IDユーザー同期」→「実行」

### SaaSアカウント同期の設定

SSO連携済みSaaSのアカウントを自動同期する場合の追加設定。

#### 1. Azure Portal でSaaSをエンタープライズアプリに登録

1. **Microsoft Entra ID** → **エンタープライズ アプリケーション** → **新しいアプリケーション**
2. ギャラリーからSaaSを検索、なければ **独自のアプリケーション** を作成
3. **シングル サインオン** → **SAML** を選択
4. SaaS側のSP情報（Entity ID, ACS URL）を設定
5. **ユーザーとグループ** → 利用者を割り当て

> **注意:** 「アプリの登録」ではなく「エンタープライズ アプリケーション」から作成すること。「アプリの登録」で作成するとOIDCモードになり、SAML SSO を選択できない。

#### 2. ツール側でSaaSと紐付け

SaaS台帳の編集画面で **「Entra ID アプリID」** にエンタープライズアプリのオブジェクトIDを入力する。
未入力の場合はSaaS名とアプリの `displayName` で自動照合する（大文字小文字を無視）。

#### 3. 動作確認

```bash
rails console

# エンタープライズアプリ一覧を取得
token = EntraClient.fetch_app_token
sps = EntraClient.fetch_service_principals(token)
puts "エンタープライズアプリ数: #{sps.count}"
sps.first(5).each { |sp| puts "  #{sp['displayName']} (#{sp['id']})" }

# 特定アプリのユーザー割り当てを確認
app_id = sps.find { |sp| sp['displayName'] =~ /Slack/i }&.dig('id')
if app_id
  assignments = EntraClient.fetch_app_role_assignments(token, app_id)
  puts "割り当てユーザー数: #{assignments.count}"
end
```

#### 4. バッチ管理画面からアカウント同期を実行

1. 管理者でログイン
2. サイドバー「バッチ管理」
3. 「Entra ID SaaSアカウント同期」→「実行」
4. 実行結果で新規作成・停止件数を確認

#### SSO 設定のテスト（RSA Test Service Provider）

Entra ID の IdP 設定が正しいかを、実際のSaaSなしで検証できるテストサービス。

1. Azure Portal でエンタープライズアプリを作成（独自アプリ）→ SAML を選択
2. 基本的な SAML 構成:
   - **識別子**: `IAMShowcase`
   - **応答 URL**: `https://sptest.iamshowcase.com/acs`
3. ユーザーを割り当て → 「テスト」ボタンでSSO実行
4. [sptest.iamshowcase.com](https://sptest.iamshowcase.com/) に SAML Assertion の内容が表示されれば成功

---

## Teams Webhook 通知の設定

承認申請やサーベイ配信時に Teams チャネルへ通知を送る機能。

### 通知が送られるタイミング

| イベント | 通知内容 |
|----------|---------|
| SaaS利用申請が提出された | 申請者、対象SaaS、理由 |
| 申請が承認された | 承認者、対象SaaS |
| 申請が却下された | 却下者、却下理由 |
| サーベイが配信された | サーベイタイトル、締切日 |

### 手順

#### 1. Teams チャネルに Incoming Webhook を追加

1. Teams で通知を受けたいチャネルを開く
2. チャネル名の横の「...」→ **「コネクタ」**（または **「ワークフロー」**）
3. **「Incoming Webhook」** を選択 → **「追加」**
4. 名前: `SaaS管理ツール`、アイコン: 任意
5. **「作成」** をクリック
6. 表示された **Webhook URL をコピー**

> **注意:** Teams の新しいバージョンでは Incoming Webhook がワークフロー経由になっている場合がある。その場合は Power Automate で「チームの Webhook 要求を受信したとき」テンプレートを使用する。

#### 2. 環境変数を設定

```bash
# .env
TEAMS_WEBHOOK_URL=https://xxxxx.webhook.office.com/webhookb2/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx@xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/IncomingWebhook/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### 3. SaaSアカウント同期用の API アクセス許可を追加

SSO連携済みSaaSのアカウントを自動同期するには、追加の API 権限が必要。

1. Azure Portal → アプリの登録 → **API のアクセス許可** → **アクセス許可の追加**
2. **Microsoft Graph** → **アプリケーションの許可** を選択
3. 以下を追加:
   - `Application.Read.All`（エンタープライズアプリ一覧の読み取り）
   - `AppRoleAssignment.ReadWrite.All`（アプリのユーザー割り当て読み取り）
4. **「（テナント名）に管理者の同意を与えます」** をクリック

> **注意:** 既に `User.Read.All` が設定済みの場合、上記2つを追加するだけでOK。

#### 4. 動作確認

```bash
rails console

TeamsNotifier.notify(
  title: "テスト通知",
  body: "SaaS管理ツールからのテスト通知です。"
)
```

Teams チャネルに Adaptive Card 形式のメッセージが届けば成功。

### 通知が不要な場合

`TEAMS_WEBHOOK_URL` を設定しなければ通知はスキップされる。アプリの動作には影響しない。

---

## PostgreSQL の設定

### タイムゾーン

アプリケーション・DBともに **JST（日本標準時）** で統一している（`config/application.rb`）。
DBに保存されるタイムスタンプ（`created_at`, `updated_at` 等）はすべてJST。

### 開発環境

`config/database.yml` のデフォルト設定で動作する。WSL 環境ではポートに注意。

```bash
# ポート確認
sudo service postgresql start
psql -p 5432 -U postgres -c "SELECT 1" 2>/dev/null && echo "5432" || echo "5433を試す"
```

ポートが異なる場合は `.env` で指定:

```bash
PGPORT=5433
```

### 本番環境

`DATABASE_URL` または `DXCECO_POC_DATABASE_PASSWORD` で設定する。

```bash
# DATABASE_URL 形式（推奨）
DATABASE_URL=postgres://user:password@host:5432/dxceco_poc_production

# または個別設定（config/database.yml の production セクションで使用）
DXCECO_POC_DATABASE_PASSWORD=xxxxxxxxxxxx
```

---

## 接続テスト手順

各外部サービスへの接続を段階的にテストする手順。

### Step 1: SSO ログイン

```bash
# .env に ENTRA_* を設定後
bin/dev
```

1. http://localhost:3000 にアクセス
2. 「Microsoft アカウントでログイン」ボタンが表示されることを確認
3. クリックして Entra ID で認証
4. ダッシュボードにリダイレクトされることを確認

**失敗時の確認ポイント:**
- `ENTRA_CLIENT_ID` / `ENTRA_CLIENT_SECRET` / `ENTRA_TENANT_ID` が正しいか
- リダイレクトURIが `http://localhost:3000/auth/entra_id/callback` で登録されているか
- `APP_URL` が `http://localhost:3000` になっているか

### Step 2: ユーザー同期

```bash
rails console

# トークン取得テスト
token = EntraClient.fetch_app_token
puts token.present? ? "OK: トークン取得成功" : "NG: トークン取得失敗"

# ユーザー取得テスト
users = EntraClient.fetch_all_users(token)
puts "OK: #{users.count} ユーザー取得"
```

**失敗時の確認ポイント:**
- API のアクセス許可 `User.Read.All` が付与されているか
- 管理者の同意が与えられているか

### Step 3: Teams 通知

```bash
rails console

TeamsNotifier.notify(title: "接続テスト", body: "SaaS管理ツールからの通知テスト")
```

**失敗時の確認ポイント:**
- Webhook URL が正しいか（有効期限切れでないか）
- Teams チャネルでコネクタが有効か

### Step 4: SaaSアカウント同期

```bash
rails console

# エンタープライズアプリの取得テスト
token = EntraClient.fetch_app_token
sps = EntraClient.fetch_service_principals(token)
puts "OK: #{sps.count} エンタープライズアプリ取得"
```

**失敗時の確認ポイント:**
- API のアクセス許可 `Application.Read.All` / `AppRoleAssignment.ReadWrite.All` が付与されているか
- 管理者の同意が与えられているか

### Step 5: 全体統合テスト

1. SSO でログイン
2. バッチ管理 → Entra ID ユーザー同期を実行
3. バッチ管理 → Entra ID SaaSアカウント同期を実行（SSO対応SaaSのアカウントが台帳に反映されることを確認）
4. 申請・承認 → 新規申請を作成（Teams 通知 + メール通知が飛ぶことを確認）
5. 操作ログで各操作が記録されていることを確認

---

## IaC 向け環境変数テンプレート

### Terraform（AWS ECS の例）

```hcl
resource "aws_ecs_task_definition" "app" {
  container_definitions = jsonencode([{
    name = "dxceco-poc"
    environment = [
      { name = "RAILS_ENV",           value = "production" },
      { name = "APP_URL",             value = "https://saas-mgmt.example.com" },
      { name = "RAILS_LOG_LEVEL",     value = "info" },
      { name = "RAILS_MAX_THREADS",   value = "5" },
      { name = "WEB_CONCURRENCY",     value = "2" },
      { name = "JOB_CONCURRENCY",     value = "2" },
      { name = "SOLID_QUEUE_IN_PUMA", value = "true" },
    ]
    secrets = [
      { name = "DATABASE_URL",          valueFrom = aws_ssm_parameter.database_url.arn },
      { name = "ENTRA_CLIENT_ID",       valueFrom = aws_ssm_parameter.entra_client_id.arn },
      { name = "ENTRA_CLIENT_SECRET",   valueFrom = aws_ssm_parameter.entra_client_secret.arn },
      { name = "ENTRA_TENANT_ID",       valueFrom = aws_ssm_parameter.entra_tenant_id.arn },
      { name = "TEAMS_WEBHOOK_URL",     valueFrom = aws_ssm_parameter.teams_webhook_url.arn },
      { name = "SECRET_KEY_BASE",       valueFrom = aws_ssm_parameter.secret_key_base.arn },
    ]
  }])
}
```

### Kubernetes（マニフェストの例）

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dxceco-poc-config
data:
  RAILS_ENV: "production"
  APP_URL: "https://saas-mgmt.example.com"
  RAILS_LOG_LEVEL: "info"
  RAILS_MAX_THREADS: "5"
  WEB_CONCURRENCY: "2"
  JOB_CONCURRENCY: "2"
  SOLID_QUEUE_IN_PUMA: "true"
---
apiVersion: v1
kind: Secret
metadata:
  name: dxceco-poc-secrets
type: Opaque
stringData:
  DATABASE_URL: "postgres://user:password@host:5432/dxceco_poc_production"
  ENTRA_CLIENT_ID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  ENTRA_CLIENT_SECRET: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  ENTRA_TENANT_ID: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  TEAMS_WEBHOOK_URL: "https://xxxxx.webhook.office.com/..."
  SECRET_KEY_BASE: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### 環境変数の分類

| 分類 | 管理方法 | 例 |
|------|---------|-----|
| 設定値 | ConfigMap / 環境変数 | `APP_URL`, `RAILS_LOG_LEVEL`, `WEB_CONCURRENCY` |
| シークレット | SSM Parameter Store / Secrets Manager / K8s Secret | `ENTRA_CLIENT_SECRET`, `DATABASE_URL`, `SECRET_KEY_BASE` |
| 通知 | シークレット | `TEAMS_WEBHOOK_URL` |
