# 認証・権限管理

## 概要
Microsoft Entra ID（旧Azure AD）によるSSO認証と、3段階のロールベースアクセス制御。開発/テスト環境ではSSO不要のdev_loginフォームを提供する。

## URL
| 画面 | URL | メソッド |
|------|-----|---------|
| ログイン画面 | `GET /login` | GET |
| Entra IDコールバック | `GET /auth/entra_id/callback` | GET |
| 開発ログイン | `POST /dev_login` | POST |
| ログアウト | `DELETE /logout` | DELETE |

## 認証フロー

### 本番環境（Entra ID SSO）
```
ログイン画面 → 「Microsoft アカウントでログイン」クリック
  → Entra ID (login.microsoftonline.com) にリダイレクト
  → Microsoft アカウントで認証
  → /auth/entra_id/callback にリダイレクト
  → ユーザー作成 or 更新 → ダッシュボード
```
- OmniAuth + OpenID Connect（OIDC）でEntra IDに接続
- OIDC Discovery で認可/トークンエンドポイントを自動解決
- 初回ログイン時にユーザーレコードを自動作成（viewerロール）
- `ENTRA_CLIENT_ID` 環境変数が設定されている場合に有効
- ログアウト時は Entra ID のセッションも終了（`/oauth2/v2.0/logout`）

### 開発/テスト環境（dev_login）
```
ログイン画面 → フォーム入力 → ダッシュボード
```
- 表示名、メールアドレス、ロールを選択してログイン
- SSO設定なしで動作
- `RAILS_ENV=development` または `test` の場合のみ有効

## ロール

| ロール | 説明 | 主な権限 |
|--------|------|---------|
| admin | 管理者（情シス） | 全機能へのフルアクセス |
| manager | マネージャー | CRUD + 承認（バッチ・ログ以外） |
| viewer | 一般ユーザー | 閲覧 + 申請 + 回答 |

## ロール別アクセスマトリクス

| 機能 | viewer | manager | admin |
|------|--------|---------|-------|
| ダッシュボード | 閲覧 | 閲覧 | 閲覧+操作ログ |
| SaaS台帳 | 閲覧 | CRUD | CRUD+CSV |
| アカウント管理 | 閲覧 | CRUD | CRUD+CSV |
| メンバー | 閲覧 | 閲覧 | 閲覧+編集 |
| サーベイ | 回答 | 回答 | CRUD+配信+分析 |
| タスク | チェック更新 | チェック更新 | CRUD+プリセット |
| 申請・承認 | 申請 | 申請+承認/却下 | 申請+承認/却下 |
| バッチ管理 | - | - | 実行+履歴 |
| 操作ログ | - | - | 閲覧 |

## セッション管理
- `session[:user_id]` でログイン状態を管理
- `require_login` フィルタで未認証アクセスをリダイレクト
- `require_admin` フィルタでadmin専用画面を保護
- ログアウト時にEntra IDのセッションも終了（SSO有効時のみ）

## 必要な環境変数

| 変数名 | 用途 |
|--------|------|
| `ENTRA_CLIENT_ID` | Entra ID アプリのクライアントID |
| `ENTRA_CLIENT_SECRET` | クライアントシークレット |
| `ENTRA_TENANT_ID` | Azure テナントID |
| `APP_URL` | アプリの公開URL（リダイレクトURI生成に使用） |

設定手順の詳細は [環境変数・外部サービス接続ガイド](../environment-setup.md#entra-id-sso-の設定) を参照。
