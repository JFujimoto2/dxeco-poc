# OWASP ZAP 脆弱性診断の導入

GitHub Issue: #16

## 概要

OWASP ZAP（Zed Attack Proxy）を使用した動的アプリケーションセキュリティテスト（DAST）を導入する。
現在の静的解析（Brakeman / bundler-audit）に加え、実行中のアプリに対する脆弱性診断を行うことで、
XSS、セキュリティヘッダー欠落、Cookie設定不備などの実行時セキュリティ問題を検出する。

## 前提

- 既存CI: Rubocop / Brakeman / bundler-audit / RSpec / Playwright E2E
- Docker が利用可能な環境
- 開発環境: `ENTRA_CLIENT_ID` 未設定時の `dev_login` フォームが利用可能
- Rails のCSRF保護（`authenticity_token`）が有効

## スキャン種別

| 種別 | 内容 | 所要時間 | 用途 |
|------|------|----------|------|
| Baseline Scan | パッシブスキャン（攻撃なし） | 2-5分 | CI/CD、本番サイト |
| Full Scan | アクティブスキャン（攻撃あり） | 30分-数時間 | ステージング環境 |
| API Scan | API定義ベース | 10-30分 | REST API（将来） |

## 実装計画

### Phase 1: ローカル実行（未認証Baseline Scan）

#### 1-1. Docker で ZAP Baseline Scan 実行

```bash
# Railsサーバー起動
bin/dev

# 別ターミナルで ZAP Baseline Scan 実行
docker run --rm -v $(pwd)/.zap:/zap/wrk/:rw \
  --network host \
  zaproxy/zap-stable \
  zap-baseline.py \
  -t http://localhost:3000 \
  -r baseline_report.html \
  -J baseline_report.json \
  -c rules.tsv \
  -m 2 \
  -I
```

**オプション説明:**
- `-t`: スキャン対象URL
- `-r`: HTMLレポート出力
- `-J`: JSONレポート出力
- `-c`: ルール設定ファイル
- `-m 2`: スパイダー実行時間（2分）
- `-I`: 警告でも失敗しない（初期段階用）

#### 1-2. ルール設定ファイル作成

`.zap/rules.tsv`:

```tsv
# rule_id	action	description
10021	WARN	X-Content-Type-Options Header Missing
10023	FAIL	Information Disclosure - Debug Error Messages
10035	WARN	Strict-Transport-Security Header Not Set
10038	WARN	Content Security Policy (CSP) Header Not Set
10096	IGNORE	Timestamp Disclosure - Unix
10202	WARN	Absence of Anti-CSRF Tokens
10049	WARN	Storable and Cacheable Content
90033	WARN	Loosely Scoped Cookie
```

#### 1-3. .gitignore に追加

```
# OWASP ZAP reports
.zap/*.html
.zap/*.json
!.zap/rules.tsv
```

### Phase 2: 認証付きスキャン

#### 2-1. dev_login を利用した認証スキャン

開発モード（`ENTRA_CLIENT_ID` 未設定）の `dev_login` を活用し、フォームベース認証でスキャンする。

ZAP Automation Framework 設定ファイル `.zap/authenticated-scan.yaml`:

```yaml
env:
  contexts:
    - name: "dxceco-poc"
      urls:
        - "http://localhost:3000"
      includePaths:
        - "http://localhost:3000/.*"
      excludePaths:
        - ".*\\.js$"
        - ".*\\.css$"
        - ".*\\.png$"
        - ".*\\.ico$"
        - ".*logout.*"
        - ".*letter_opener.*"
      authentication:
        method: "form"
        parameters:
          loginPageUrl: "http://localhost:3000/dev_login"
          loginRequestUrl: "http://localhost:3000/dev_login"
          loginRequestBody: "email={%username%}"
        verification:
          method: "response"
          loggedInRegex: "\\Qログアウト\\E"
          loggedOutRegex: "\\Qログイン\\E"
      sessionManagement:
        method: "cookie"
      users:
        - name: "admin-user"
          credentials:
            username: "admin@example.com"
    technology:
      exclude:
        - "Language.ASP"
        - "Language.PHP"
        - "Language.Java"
        - "Language.Python"
  parameters:
    failOnError: false
    progressToStdout: true

jobs:
  - type: spider
    parameters:
      maxDuration: 3
      user: "admin-user"
  - type: spiderAjax
    parameters:
      maxDuration: 3
      user: "admin-user"
  - type: passiveScan-wait
    parameters:
      maxDuration: 5
  - type: report
    parameters:
      template: "traditional-html-plus"
      reportDir: "/zap/wrk"
      reportFile: "authenticated_report"
    risks:
      - high
      - medium
      - low
```

#### 2-2. 実行コマンド

```bash
docker run --rm -v $(pwd)/.zap:/zap/wrk/:rw \
  --network host \
  zaproxy/zap-stable \
  zap.sh -cmd \
  -autorun /zap/wrk/authenticated-scan.yaml
```

#### 2-3. Rails側の対応

- CSRF トークン: ZAP は `authenticity_token` を自動検出（Rails デフォルト）
- Cookie 設定: `config/environments/production.rb` でセキュリティ属性を確認
  - `secure: true`（HTTPS環境）
  - `same_site: :lax`
  - `httponly: true`

### Phase 3: CI/CD 統合

#### 3-1. GitHub Actions ワークフロー追加

`.github/workflows/ci.yml` に `scan_dast` ジョブを追加:

```yaml
scan_dast:
  name: DAST Scan (OWASP ZAP)
  runs-on: ubuntu-latest
  needs: test
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'

  services:
    postgres:
      image: postgres:16
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
      ports:
        - 5432:5432
      options: >-
        --health-cmd pg_isready
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5

  env:
    RAILS_ENV: test
    DATABASE_URL: postgres://postgres:postgres@localhost:5432/dxceco_poc_test

  steps:
    - uses: actions/checkout@v4

    - uses: ruby/setup-ruby@v1
      with:
        bundler-cache: true

    - name: Setup database
      run: bin/rails db:create db:migrate

    - name: Seed test data
      run: bin/rails db:seed

    - name: Start Rails server
      run: |
        bin/rails server -p 3000 &
        sleep 10
        curl -f http://localhost:3000 || exit 1

    - name: OWASP ZAP Baseline Scan
      uses: zaproxy/action-baseline@v0.14.0
      with:
        target: "http://localhost:3000"
        rules_file_name: ".zap/rules.tsv"
        cmd_options: "-m 2 -I"
        allow_issue_writing: false
        fail_action: false

    - name: Upload ZAP Report
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: zap-report
        path: |
          report_html.html
          report_json.json
        retention-days: 30
```

#### 3-2. 段階的な厳格化

| 期間 | 設定 | 目的 |
|------|------|------|
| 導入初期（1-2週） | `fail_action: false` | レポート収集、ベースライン把握 |
| 安定期（3-4週） | `fail_action: true` + 主要ルールのみ FAIL | 重要な脆弱性のみブロック |
| 運用期（5週以降） | FAIL ルール拡大 | 継続的なセキュリティ品質維持 |

## Rails セキュリティヘッダー対応（ZAP指摘の想定対応）

ZAP で検出が見込まれるヘッダー不備への対応:

```ruby
# config/application.rb または middleware
config.action_dispatch.default_headers.merge!(
  "X-Content-Type-Options" => "nosniff",
  "X-Frame-Options" => "DENY",
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=()",
  "Referrer-Policy" => "strict-origin-when-cross-origin"
)
```

CSP ヘッダーは `content_security_policy` initializer で設定:

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, "https://cdn.jsdelivr.net"
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self, "https://cdn.jsdelivr.net"
    policy.style_src   :self, :unsafe_inline, "https://cdn.jsdelivr.net"
    policy.connect_src :self
  end
end
```

## 成果物チェックリスト

### Phase 1: ローカル実行
- [ ] `.zap/rules.tsv` ルール設定ファイル作成
- [ ] `.gitignore` にレポートファイル除外追加
- [ ] Docker で Baseline Scan 実行・レポート確認
- [ ] 検出された脆弱性の分類（真の問題 / 誤検知）

### Phase 2: 認証付きスキャン
- [ ] `.zap/authenticated-scan.yaml` 作成
- [ ] dev_login を利用した認証スキャン実行
- [ ] 保護ルートのスキャン結果確認
- [ ] セキュリティヘッダー対応（検出結果に応じて）

### Phase 3: CI/CD 統合
- [ ] `.github/workflows/ci.yml` に `scan_dast` ジョブ追加
- [ ] `fail_action: false` で初期運用開始
- [ ] 2週間のレポート収集後、ルール厳格化
- [ ] Rubocop + Brakeman + RSpec + Playwright + ZAP 全パス確認
