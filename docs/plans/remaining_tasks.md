# POC 残タスク一覧

## 概要

DXECOとの比較分析を踏まえ、POCの説得力を高めるために追加すべき機能と、運用本番化に向けた課題を整理する。

---

## 0. バグ修正・改善（完了済み）

### 0.1 CSVインポート修正 & テンプレートダウンロード ✅

- [x] Turbo競合修正（`data: { turbo: false }` でフォーム送信が動作するように）
- [x] アクセス制御追加（`require_admin_or_manager` — admin/managerのみ）
- [x] CSVテンプレートダウンロード機能（BOM付きUTF-8、サンプル行付き）
- [x] インポートモーダルにテンプレートDLリンク追加
- [x] RSpecリクエストスペック追加（import + download_template + 権限テスト）
- [x] Playwright E2Eテスト追加（`e2e/csv-import.spec.ts` — 5テスト）
- [x] Bootstrap/Popper.js をCDN配信に変更（ESMサブモジュール問題を解消）

---

## 1. 追加機能（デモ強化）

### 1.1 契約更新アラート ✅

- [x] ダッシュボードに「更新期限が近い契約」カードを追加（30日以内）
- [x] 期限30日前・7日前にTeams通知を送信（ContractRenewalAlertJob）
- [x] 期限切れ契約の件数表示
- [x] バッチ管理画面に手動実行ボタン追加
- [x] seedデータにデモ用の期限設定（7日以内・30日以内・期限切れ）
- [x] RSpecテスト作成（モデル5件 + ダッシュボード3件 + ジョブ3件 + バッチ1件）
- [x] Playwright E2Eテスト追加（`e2e/contract-alert.spec.ts` — 3テスト）

**根拠:** `saas_contracts.expires_on` が既にあり、通知基盤（TeamsNotifier）も整備済み。DXECOにもある機能なので「同等以上」と言いやすい。

### 1.2 サーベイ → タスク連携 ✅

- [x] サーベイ結果画面に「不要アカウント一覧」セクションを追加
- [x] 「利用していない」回答から削除タスクをワンクリック生成
- [x] サーベイ → 検出 → タスク → 完了の一気通貫フローを実現
- [x] RSpecテスト作成（リクエスト4件）
- [x] Playwright E2Eテスト追加（`e2e/survey-task.spec.ts` — 2テスト）

**詳細計画:** `docs/plans/survey_task_integration.md`

**根拠:** 既存のサーベイ機能とタスク管理機能を接続するだけ。デモで「検出から対応まで一画面で完結」を見せられる。

### 1.3 Entra ID SaaSアカウント自動同期 + パスワード期限検出 ✅

- [x] Graph API でエンタープライズアプリのユーザー割り当て一覧を取得
- [x] EntraAccountSyncJob: SaaSアカウント台帳との差分同期（新規・削除検出）
- [x] パスワード期限切れ / 期限間近のユーザー検出（`lastPasswordChangeDateTime`）
- [x] ダッシュボードにパスワード期限アラート表示
- [x] バッチ管理画面に手動実行ボタン追加
- [x] 同期結果の Teams 通知
- [x] RSpecテスト作成（EntraClient 3件 + Job 7件 + User 3件 + Dashboard 3件 + Batch 1件 + UserSync 1件 = 18件）
- [x] Playwright E2Eテスト追加（`e2e/entra-account-sync.spec.ts` — 2テスト）

**詳細計画:** `docs/plans/entra_account_sync.md`
**GitHub Issue:** [#10](https://github.com/JFujimoto2/dxeco-poc/issues/10)

**根拠:** SSO連携済みSaaSのアカウントは Graph API で自動取得可能。手動管理からの脱却を実証できる。パスワード期限管理も Graph API から取得でき、セキュリティ面の訴求力が高い。

### 1.4 コスト可視化 ✅

- [x] ダッシュボードに月額/年額コスト合計を表示
- [x] カテゴリ別コスト内訳（doughnut chart）
- [x] Chart.js をimportmapで導入
- [x] Stimulus コントローラー（cost_chart_controller.js）作成
- [x] RSpecテスト作成（モデル6件 + ダッシュボード3件 = 9件）
- [x] Playwright E2Eテスト追加（`e2e/cost-visualization.spec.ts` — 2テスト）

**詳細計画:** `docs/plans/cost_visualization.md`
**GitHub Issue:** [#6](https://github.com/JFujimoto2/dxeco-poc/issues/6)

**根拠:** `saas_contracts.price_cents` が既にある。経営層へのデモで「260件のSaaSに年間いくら払っているか」が一目で見えると効果的。

### 1.5 CSVエクスポート（優先度: 低〜中 / 工数: 0.5日）

- [ ] SaaS台帳のCSVエクスポート
- [ ] アカウント一覧のCSVエクスポート
- [ ] 監査ログのCSVエクスポート
- [ ] RSpecテスト作成

**GitHub Issue:** [#7](https://github.com/JFujimoto2/dxeco-poc/issues/7)

**根拠:** インポートは既にあるがエクスポートがない。監査対応・経営報告で「データを出せる」のは実用上重要。

---

## 2. 運用本番化に向けた課題

### 2.1 保守コストの見通し

テストカバレッジ（RSpec 247件 + Playwright E2E 70件）とCI自動化が整備済みのため、日常的な保守コストは低い想定。

| 項目 | 頻度 | 工数 |
|------|------|------|
| Rails/gemのセキュリティパッチ | 数ヶ月に1回 | 数時間 |
| Ruby/Railsメジャーバージョンアップ | 年1回 | 1〜2日 |
| 軽微な機能改修・要望対応 | 随時 | 都度判断 |

### 2.2 承認フローの改修（本番移行時に必要）

現在は「申請 → 承認/却下」の1段階のみ。実運用に合わせて以下の対応が必要になる見込み。

- [ ] 会社の承認ルート（部門長→情シス等）に合わせた多段階承認
- [ ] 部門別・金額別の承認ルーティング
- [ ] 承認者の自動割り当てルール
- [ ] 承認期限・エスカレーション

※ 実際の運用フローを確認してから設計する

### 2.3 未実装のDXECO機能（本番移行時に要検討）

| 機能 | 必要性 | 備考 |
|------|--------|------|
| シャドーIT管理（ブラウザ拡張） | 低 | 精度に課題あり。導入ハードルも高い |
| IT資産管理（PC・携帯） | 低 | SaaS管理と別ツールでも可 |
| 新規アカウント検知 | 中 | Entra ID同期の拡張で対応可能 |
| Zapier連携 | 低 | 現時点では不要 |

---

## 3. 進め方

1. ~~**0.1 CSVインポート修正** を最優先で対応~~ ✅ 完了
2. ~~**1.1 契約更新アラート**~~ ✅ 完了 + ~~**1.2 サーベイ→タスク連携**~~ ✅ 完了
3. ~~**1.3 Entra ID SaaSアカウント自動同期 + パスワード期限検出**~~ ✅ 完了
4. ~~**1.4 コスト可視化**~~ ✅ 完了
5. **1.5 CSVエクスポート** は本番移行フェーズで対応 🔧 次のタスク

---

作成日: 2026年2月11日
更新日: 2026年2月14日（1.4 コスト可視化 完了）
