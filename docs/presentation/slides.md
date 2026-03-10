---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  section {
    font-family: 'Meiryo UI', 'Meiryo', sans-serif;
    font-size: 22px;
    padding: 40px 50px;
    color: #333333;
    background-color: #ffffff;
  }
  section.title {
    background: #0058a3;
    color: #ffffff;
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  section.title h1 {
    font-size: 2.2em;
    border: none;
    color: #ffffff;
    margin-bottom: 0.2em;
  }
  section.title h2 {
    font-size: 1.1em;
    font-weight: 400;
    color: #cce0f0;
    border: none;
  }
  section.title h3 {
    font-size: 0.85em;
    font-weight: 400;
    color: #cce0f0;
  }
  section.section-header {
    background: #0058a3;
    color: #ffffff;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  section.section-header h1 {
    font-size: 2.2em;
    border: none;
    color: #ffffff;
  }
  section.demo {
    background: #1a1a2e;
    color: #ffffff;
    text-align: center;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }
  section.demo h1 {
    font-size: 2.0em;
    border: none;
    color: #ffffff;
  }
  section.demo h2 {
    font-size: 1.2em;
    font-weight: 400;
    color: #aaaaaa;
    border: none;
  }
  h1 {
    font-size: 1.5em;
    color: #0058a3;
    border-bottom: 2px solid #0058a3;
    padding-bottom: 0.15em;
    margin-bottom: 0.4em;
  }
  h2 {
    font-size: 1.15em;
    color: #0058a3;
    margin-top: 0.3em;
    margin-bottom: 0.2em;
  }
  h3 {
    font-size: 1.0em;
    color: #444444;
    margin-top: 0.3em;
    margin-bottom: 0.15em;
  }
  table {
    font-size: 0.82em;
    width: 100%;
  }
  th {
    background-color: #0058a3;
    color: #ffffff;
    font-weight: 600;
  }
  td, th {
    padding: 4px 10px;
  }
  strong {
    color: #c41e00;
  }
  ul, ol {
    font-size: 0.92em;
    margin-top: 0.2em;
  }
  li {
    margin-bottom: 0.15em;
  }
  blockquote {
    border-left: 4px solid #0058a3;
    background: #eef4fb;
    color: #333333;
    padding: 0.4em 1em;
    margin: 0.5em 0;
    font-size: 0.92em;
  }
  pre {
    font-size: 0.75em;
    background: #f5f5f5;
    padding: 0.6em;
  }
  code {
    font-size: 0.85em;
  }
  footer {
    font-size: 0.55em;
    color: #999999;
  }
---

<!-- _class: title -->

# SaaS管理ツール
## 自社開発POC 紹介 — デジタル推進部向け

<br>

情報システム部
2026年3月

---

# 本日のアジェンダ

1. **現場の課題** — なぜSaaS管理ツールが必要か
2. **デモ** — 実際に動くツールを見る（動画）
3. **POCの成果** — 16機能・364テスト
4. **コスト** — 月額約5,000円で運用
5. **本番化計画** — 会社テナントへの移行
6. **質疑応答**

---

<!-- _class: section-header -->

# 1. 現場の課題

---

# 現状の3つの課題

| # | 課題 | 現状 |
|---|------|------|
| ① | **誰も全社のSaaS利用状況を把握していない** | 内部監査がWEBチームのヒアリング一覧で確認しているのが実態 |
| ② | **管理がExcel・人の記憶頼り** | 260件のSaaSそれぞれに管理者がいて、各自で棚卸し・PW変更 |
| ③ | **入退社時のアカウント管理が漏れる** | 1つずつ手作業で確認。漏れが多い |

---

# 棚卸しの実態

```
年1回の棚卸し指示（監査の観点）
  → 代表者が各部門にヒアリング
    → 各部門から回答を回収
      → Excelに集約
        → 誤っている部分を1つずつ確認
```

<br>

> **そもそもSaaS台帳が存在せず、管理は現場まかせ。棚卸しも年1回が精一杯で、実態を正確に把握できていない。**

---

# 現場が求めている機能

| 優先度 | 機能 | 解決したいこと |
|--------|------|---------------|
| **1** | **SaaS台帳の一元管理** | 何のSaaSを使っていて、誰が管理者で、いくら払っているかを一箇所で見たい |
| **2** | **棚卸しアンケート（サーベイ）** | 地獄フローを「アンケート配信→回答→自動集計→台帳反映」に置き換えたい |
| **3** | **退職者アカウントの自動検出** | 退職者のアカウントが各SaaSに残っていないか自動で検出したい |
| **4** | **入退社時のアカウント管理** | どのSaaSのアカウントを作成/削除するかのチェックリストを定型化したい |

---

<!-- _class: section-header -->

# 2. デモ

---

<!-- _class: demo -->

# 🎬 デモ動画

## SaaS管理ツール — 操作フロー

---

# デモの流れ

| # | 操作 | ポイント |
|---|------|---------|
| 1 | Entra IDでログイン | 会社アカウントでワンクリックログイン（SSO） |
| 2 | ダッシュボード | SaaS件数・コスト・契約更新・タスク進捗を一目で把握 |
| 3 | SaaS台帳 | 260件の一元管理。検索・フィルタ・CSV入出力 |
| 4 | サーベイ配信→回答 | 棚卸しアンケートの配信→回答→自動集計 |
| 5 | 退職者アカウント検出 | Entra IDの退職者情報と台帳を自動突合せ |
| 6 | タスク管理 | 退職者のチェックリストを自動生成 |
| 7 | 操作ログ | 全データ変更の自動記録（監査対応） |

---

<!-- _class: section-header -->

# 3. POCの成果

---

# 自社開発（Rails）の現状

### POC完成済み — 16機能・364テスト

| 指標 | 値 |
|------|-----|
| 実装済み機能 | 16機能（台帳・サーベイ・退職者検出・タスク等） |
| テスト数 | RSpec 291 + Playwright E2E 73 = **計364件** |
| テストカバレッジ | **95.6%**（行） |
| セキュリティ警告 | Brakeman **0件** |
| 本番化までの追加作業 | **約3〜4日**（Azure環境構築のみ） |

---

<!-- _class: section-header -->

# 4. コスト

---

# 月額コスト内訳

| リソース | 月額 |
|---------|------|
| PostgreSQL（常時起動） | ~¥3,750 |
| Container Registry | ~¥750 |
| Container Apps（月1回起動） | ~¥100 |
| Key Vault / VNet / Monitor | ほぼ¥0 |
| SSL証明書 | ¥0 |
| メール送信（Exchange Online SMTP） | ¥0（E5に含まれる） |
| **合計** | **約¥4,650〜6,000** |

> コストの95%以上はPostgreSQL（¥3,750）とACR（¥750）の固定費。

---

# DXECO vs 自社開発：コスト比較

<br>

| | 自社開発 | DXECO |
|---|---------|-------|
| **月額** | **約¥4,700** | 約¥170,000 |
| **年額** | **約¥56,000** | 約¥2,040,000 |
| **5年間** | **約¥280,000** | 約¥10,200,000 |

<br>

> 自社開発はDXECOの約**30分の1**のコスト。

---

# 5年間累計コスト比較

<br>

| 期間 | 自社開発 | DXECO | 削減額 |
|------|---------|-------|--------|
| 1年目 | 約6万円 | 204万円 | **約198万円** |
| 3年累計 | 約17万円 | 612万円 | **約595万円** |
| **5年累計** | **約28万円** | **1,020万円** | **約990万円** |

<br>

> 5年間で**約990万円の削減**。

---

<!-- _class: section-header -->

# 5. 本番化計画

---

# 会社テナントへの移行

| 項目 | POC（現状） | 本番 |
|------|------------|------|
| Azureテナント | 個人 | **会社テナント（Entra IDと同一）** |
| 環境数 | 1（dev兼デモ） | **1（prod のみ）** |
| セキュリティ | 最低限 | **VNet + Key Vault + 監視** |
| コンテナ | min 0（手動） | **min 0 + CRONで月次バッチ自動実行** |
| DB | 個人サブスクリプション | **会社サブスクリプション（常時起動）** |
| メール | 未設定 | **Exchange Online SMTP（E5に含まれる）** |
| 開発環境 | Azure上 | **ローカル Docker Compose** |

---

# 運用方針

### コンテナ（min 0運用）
- 普段は停止。月次バッチ時（毎月1日）のみCRONで自動起動
- 管理者がアクセスすれば自動起動（コールドスタート: 数十秒〜1分）

### 月次バッチ（毎月1日 自動実行）

| バッチ | 内容 |
|--------|------|
| Entra IDユーザー同期 | 退職者検出の前提処理 |
| 退職者アカウント検出 | 残存アカウントの通知 |
| 契約更新チェック | 30日以内の契約更新を通知 |
| SaaSアカウント同期 | Entra IDエンタープライズアプリからの同期 |

---

# 構築の進め方

| ステップ | 内容 | 所要時間 |
|---------|------|---------|
| 1. 社内確認 | サブスクリプション・権限・Entra ID管理者 | 1〜2週間 |
| 2. インフラ構築 | VNet → PostgreSQL → ACR → Container Apps → Key Vault | 1日 |
| 3. Entra ID設定 | アプリ登録 → API権限 → Admin Consent | 0.5日 |
| 4. CI/CD設定 | GitHub Secrets → デプロイワークフロー → テストデプロイ | 0.5日 |
| 5. データ移行・動作確認 | 初期データ投入 → 全機能テスト | 1〜2日 |
| **技術作業の合計** | | **約3〜4日** |

---

# まとめ

### 自社開発（Rails）を推奨する理由

| ポイント | 内容 |
|---------|------|
| **もう動いている** | 16機能・364テスト。本番化まで3〜4日 |
| **月約5,000円** | DXECOの30分の1のコスト |
| **現場の最重要機能に対応** | 台帳連動型サーベイ・退職者自動検出が実装済み |
| **会社テナントで安全** | Entra ID SSO・VNet統合・Key Vault・監査ログ標準装備 |

<br>

> **承認フローは別途検討。まずは台帳管理・サーベイ・退職者検出・チェックリストの4機能で本番化を進めたい。**

---

<!-- _class: title -->

# ありがとうございました

<br>

### 質疑応答

<br>
<br>

SaaS管理ツール — 情報システム部
