# Playwright E2Eテスト導入

## 概要
RSpecリクエストスペックでは検出できないブラウザベースの問題（ルーティングエラー、Turboキャッシュ問題、UI崩れ）を検出するため、Playwright E2Eテストを導入。

## 技術選定
- **@playwright/test** v1.58.2（Node.js standalone）
- Chromium のみ（軽量に保つ）
- `webServer` 設定でRailsサーバーを自動起動（ポート3001）

## 成果物

- [x] `package.json` - npm設定
- [x] `playwright.config.ts` - Playwright設定
- [x] `e2e/helpers/auth.ts` - dev_loginによる認証ヘルパー
- [x] `e2e/smoke.spec.ts` - 全25画面のスモークテスト
- [x] `e2e/navigation.spec.ts` - サイドバーナビゲーションテスト（10テスト）
- [x] `e2e/crud.spec.ts` - CRUD操作テスト（5テスト）
- [x] `e2e/viewer-access.spec.ts` - viewerロールアクセス制限テスト（14テスト）
- [x] `e2e/global-teardown.ts` - テスト後のDB cleanup（RSpec互換）
- [x] `.gitignore` 更新（node_modules, playwright-report, test-results）

## テスト数
- **E2E: 54テスト** (全パス)
- **RSpec: 151テスト** (全パス、影響なし)

## 実行方法
```bash
# E2Eテスト実行
npx playwright test

# UIモードでデバッグ
npx playwright test --ui

# レポート表示
npx playwright show-report

# RSpecと連続実行（globalTeardownで自動cleanup）
npx playwright test && bundle exec rspec
```

## 注意事項
- `globalTeardown` がE2Eテスト後にテストDBをクリーンアップ（RSpecとの共存）
- テスト環境で `db:seed` データが必要（`webServer` が自動実行）
- アセットプリコンパイルが必要: `RAILS_ENV=test bin/rails assets:precompile`
