# ドキュメント一覧

## 概要・企画

| ファイル | 内容 |
| --- | --- |
| [機能概要.md](機能概要.md) | システム全体の機能マップと各機能の説明 |
| [セキュリティ対策.md](セキュリティ対策.md) | 認証・暗号化・インフラ・アプリ・CI/CDのセキュリティ対策 |
| [自社開発_タスク_機能一覧.md](自社開発_タスク_機能一覧.md) | POC開発計画と実装状況（全16機能） |
| [社内開発ガイドライン.md](社内開発ガイドライン.md) | 社内開発の方針・ルール |
| [社内開発セキュリティガイドライン.md](社内開発セキュリティガイドライン.md) | 社内開発におけるセキュリティガイドライン |

## 運用ガイド

| ファイル | 対象者 | 内容 |
| --- | --- | --- |
| [user-guide.md](user-guide.md) | 全ユーザー | 画面操作・ロール別ガイド・POCトライアル手順 |
| [operations.md](operations.md) | 開発者 | 開発フロー・TDD・CI/CD・テスト戦略・DB操作 |
| [environment-setup.md](environment-setup.md) | 開発者 | 環境変数・Entra ID SSO・Graph API・Teams Webhook・SMTP設定 |

## プレゼン資料 (`presentation/`)

| ファイル | 内容 |
| --- | --- |
| [slides.md](presentation/slides.md) | Marpスライド |
| [slides.pptx](presentation/slides.pptx) | PowerPointスライド |
| [screenshots_guide.md](presentation/screenshots_guide.md) | 画面説明書（上長提出用） |
| `screenshots/` | 画面キャプチャ画像 |

## 機能仕様 (`features/`)

| # | ファイル | 機能 |
| --- | --- | --- |
| 01 | [dashboard](features/01_dashboard.md) | ダッシュボード |
| 02 | [saas_ledger](features/02_saas_ledger.md) | SaaS台帳 |
| 03 | [account_management](features/03_account_management.md) | アカウント管理 |
| 04 | [members](features/04_members.md) | メンバー管理 |
| 05 | [survey](features/05_survey.md) | サーベイ（棚卸し） |
| 06 | [task_management](features/06_task_management.md) | タスク管理 |
| 07 | [approval_workflow](features/07_approval_workflow.md) | 申請・承認 |
| 08 | [batch_management](features/08_batch_management.md) | バッチ管理 |
| 09 | [audit_log](features/09_audit_log.md) | 操作ログ |
| 10 | [authentication](features/10_authentication.md) | 認証・認可 |
| 11 | [csv_import](features/11_csv_import.md) | CSV取込 |
| 12 | [email_notification](features/12_email_notification.md) | メール通知 |
| 13 | [contract_renewal_alert](features/13_contract_renewal_alert.md) | 契約更新アラート |
| 14 | [cost_visualization](features/14_cost_visualization.md) | コスト可視化 |
| 15 | [csv_export](features/15_csv_export.md) | CSVエクスポート |
| 16 | [entra_account_sync](features/16_entra_account_sync.md) | SaaSアカウント同期 |

## 実装計画 (`plans/`)

機能実装時のTDD計画書。チェックリスト付き。

| ファイル | 内容 |
| --- | --- |
| [remaining_tasks.md](plans/remaining_tasks.md) | 残タスク一覧（実装状況） |
| phase1〜4 | フェーズ別実装計画 |
| 各機能計画書 | 個別機能のTDD実装計画 |

## インフラ (`infra/`)

| ファイル | 内容 |
| --- | --- |
| [インフラ構成.md](../infra/インフラ構成.md) | デプロイ済みリソースの実構成・運用コマンド |
| [インフラ構成図.drawio](../infra/インフラ構成図.drawio) | インフラ構成図（draw.io） |
| DB接続情報.md | DB接続情報（gitignore対象、ローカルのみ） |
