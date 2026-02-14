# コスト可視化

## 概要

ダッシュボードにSaaSのコスト情報を可視化するセクションを追加する。月額/年額コスト合計の表示と、カテゴリ別コスト内訳のグラフを表示する。

**GitHub Issue:** [#6](https://github.com/JFujimoto2/dxeco-poc/issues/6)

## 前提

- `saas_contracts.price_cents` にサイクルあたりの金額が格納済み
- `saas_contracts.billing_cycle` で `monthly` / `yearly` を区別
- `saases.category` でカテゴリ別グルーピングが可能（一般IT / 不動産管理 / バックオフィス）
- seedデータに30件のSaaS契約が存在

## コスト計算ロジック

`price_cents` は **サイクルあたりの金額** のため、月額/年額への正規化が必要:

| billing_cycle | 月額換算 | 年額換算 |
|---------------|----------|----------|
| monthly | price_cents | price_cents × 12 |
| yearly | price_cents ÷ 12 | price_cents |

## 実装計画

### 1. SaasContract モデルにコスト集計メソッド追加

**ファイル**: `app/models/saas_contract.rb`

```ruby
def monthly_cost_cents
  billing_cycle == "yearly" ? (price_cents || 0) / 12 : (price_cents || 0)
end

def annual_cost_cents
  billing_cycle == "yearly" ? (price_cents || 0) : (price_cents || 0) * 12
end

def self.total_monthly_cost_cents
  all.sum { |c| c.monthly_cost_cents }
end

def self.total_annual_cost_cents
  all.sum { |c| c.annual_cost_cents }
end
```

### 2. DashboardController にコストデータ追加

**ファイル**: `app/controllers/dashboard_controller.rb`

```ruby
contracts = SaasContract.includes(:saas).where.not(price_cents: nil)
@total_monthly_cost = contracts.sum { |c| c.monthly_cost_cents }
@total_annual_cost = contracts.sum { |c| c.annual_cost_cents }
@cost_by_category = contracts.group_by { |c| c.saas.category || "未分類" }
  .transform_values { |cs| cs.sum(&:monthly_cost_cents) }
  .sort_by { |_, v| -v }
```

### 3. Chart.js をimportmapで導入

**ファイル**: `config/importmap.rb`

```ruby
pin "chart.js", to: "https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"
```

### 4. Stimulus コントローラーでグラフ描画

**ファイル**: `app/javascript/controllers/cost_chart_controller.js`

- `connect()` でChart.jsの円グラフ（doughnut chart）を初期化
- data属性からカテゴリ名・金額を取得
- レスポンシブ対応

### 5. ダッシュボードにコストセクション追加

**ファイル**: `app/views/dashboard/index.html.erb`

ステータスカード行の下、契約更新アラートの上に配置:

- 左側（col-md-4）: 月額コスト合計カード + 年額コスト合計カード
- 右側（col-md-8）: カテゴリ別コスト内訳の円グラフ（doughnut chart）
- カテゴリごとに色分け
- 金額は `number_to_currency` で `¥` 表示

### 6. テスト

#### RSpec

- **`spec/models/saas_contract_spec.rb`**: `monthly_cost_cents`, `annual_cost_cents` のテスト
- **`spec/requests/dashboard_spec.rb`**: コストセクション表示テスト

#### Playwright E2E

- **`e2e/cost-visualization.spec.ts`**: ダッシュボードにコストセクションが表示される

## 成果物チェックリスト

- [x] SaasContract モデルにコスト計算メソッド追加
- [x] DashboardController にコストデータ追加
- [x] Chart.js をimportmapで導入
- [x] Stimulus コントローラー（cost_chart_controller.js）作成
- [x] ダッシュボードにコストセクション追加
- [x] RSpec テスト作成（247テスト全パス）
- [x] Playwright E2E テスト追加（70テスト全パス）
- [x] Rubocop + RSpec + Playwright 全パス確認
