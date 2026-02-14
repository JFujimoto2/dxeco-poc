# コスト可視化

## 概要
ダッシュボードにSaaS契約コストの合計とカテゴリ別内訳を表示する。経営層への報告やコスト最適化の判断材料を提供する。

## ダッシュボード表示

### コスト合計カード
| カード | 表示内容 |
|--------|---------|
| 月額コスト | 全契約の月額換算合計（万円単位） |
| 年額コスト | 全契約の年額換算合計（万円単位） |

### カテゴリ別コスト内訳
- **Doughnut Chart**: Chart.js によるカテゴリ別月額コストの円グラフ
- **内訳テーブル**: カテゴリ名 + 月額コスト（円）をコストの高い順に表示

## コスト計算ロジック

`SaasContract` モデルのメソッド:

| メソッド | ロジック |
|----------|---------|
| `monthly_cost_cents` | `billing_cycle == "yearly"` → `price_cents / 12`、それ以外 → `price_cents` |
| `annual_cost_cents` | `billing_cycle == "yearly"` → `price_cents`、それ以外 → `price_cents * 12` |

- `price_cents` が `nil` の場合は 0 として扱う
- `billing_cycle`: `monthly` または `yearly`

## 技術スタック
- **Chart.js**: importmap CDN 経由で配信（`chart.js/auto`）
- **Stimulus**: `cost_chart_controller.js` でチャート描画
- チャートデータは `data-cost-chart-labels-value` / `data-cost-chart-values-value` でHTMLから受け渡し

## アクセス権限
全ロールに表示。
