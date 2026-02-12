# CSVインポート修正 & テンプレートダウンロード機能 ✅

## 概要

CSVインポート機能のバグ修正・アクセス制御追加・テンプレートCSVダウンロード機能を実装。

## 修正した問題

1. **インポートボタンが反応しない（Turbo競合）**: `form_tag`のフォームをTurbo Driveが自動インターセプトし、Bootstrapモーダル内の`multipart/form-data`送信が正常に動作しなかった → `data: { turbo: false }` で解決
2. **アクセス制御なし**: viewerでもインポート実行可能だった → `require_admin_or_manager` で制限
3. **Bootstrap JS未読み込み**: `@popperjs/core` のESMサブモジュール参照がPropshaftで解決不可 → CDN配信に変更
4. **テンプレートCSVダウンロード機能がなかった** → `download_template`アクション追加
5. **リクエストスペック未作成** → import + download_template + 権限テストを追加

## 成果物チェックリスト

- [x] インポートフォームの Turbo 競合修正（`data: { turbo: false }`）
- [x] `require_admin_or_manager` メソッド追加
- [x] SaaSインポートにアクセス制御追加
- [x] アカウントインポートにアクセス制御追加
- [x] SaaSテンプレートダウンロードアクション追加
- [x] アカウントテンプレートダウンロードアクション追加
- [x] ルーティング更新
- [x] インポートモーダルにテンプレートDLリンク追加（SaaS）
- [x] インポートモーダルにテンプレートDLリンク追加（アカウント）
- [x] リクエストスペック追加（SaaS import + download_template）
- [x] リクエストスペック追加（アカウント import + download_template）
- [x] Playwright E2Eテスト追加（`e2e/csv-import.spec.ts`）
- [x] Bootstrap/Popper.js CDN配信に変更
- [x] `docs/features/11_csv_import.md` 更新
- [x] Rubocop + RSpec + Playwright 全パス確認
