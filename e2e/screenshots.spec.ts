import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";
import path from "path";

const screenshotDir = path.join(__dirname, "..", "docs", "screenshots");

test.describe.configure({ mode: "serial" });

// --- 01: ログイン画面 ---
test("01_login", async ({ page }) => {
  await page.goto("/login");
  await page.waitForLoadState("networkidle");
  await page.screenshot({ path: path.join(screenshotDir, "01_login.png") });
});

// --- ログイン後の画面群 ---
test.describe("Authenticated screenshots", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  // --- 02: ダッシュボード上部 ---
  test("02_dashboard_overview", async ({ page }) => {
    await page.goto("/");
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "02_dashboard_overview.png"),
    });
  });

  // --- 03: ダッシュボード セキュリティリスク ---
  test("03_dashboard_security", async ({ page }) => {
    await page.goto("/");
    await page.waitForLoadState("networkidle");
    const securityHeading = page.locator("text=セキュリティリスク").first();
    if ((await securityHeading.count()) > 0) {
      await securityHeading.scrollIntoViewIfNeeded();
      await page.waitForTimeout(300);
    }
    await page.screenshot({
      path: path.join(screenshotDir, "03_dashboard_security.png"),
    });
  });

  // --- 04: ダッシュボード コスト概要 ---
  test("04_dashboard_cost", async ({ page }) => {
    await page.goto("/");
    await page.waitForLoadState("networkidle");
    const costHeading = page.locator("text=コスト概要").first();
    if ((await costHeading.count()) > 0) {
      await costHeading.scrollIntoViewIfNeeded();
      await page.waitForTimeout(300);
    }
    await page.screenshot({
      path: path.join(screenshotDir, "04_dashboard_cost.png"),
    });
  });

  // --- 05: SaaS台帳一覧 ---
  test("05_saas_list", async ({ page }) => {
    await page.goto("/saases");
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "05_saas_list.png"),
    });
  });

  // --- 06: SaaS詳細 ---
  test("06_saas_detail", async ({ page }) => {
    await page.goto("/saases");
    await page.waitForLoadState("networkidle");
    await page.locator("table tbody tr td a").first().click();
    await page.waitForURL(/\/saases\/\d+$/);
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "06_saas_detail.png"),
      fullPage: true,
    });
  });

  // --- 07: アカウント管理 ---
  test("07_account_list", async ({ page }) => {
    await page.goto("/saas_accounts");
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "07_account_list.png"),
    });
  });

  // --- 08: メンバー一覧 ---
  test("08_members_list", async ({ page }) => {
    await page.goto("/users");
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "08_members_list.png"),
    });
  });

  // --- 09: メンバー詳細 ---
  test("09_member_detail", async ({ page }) => {
    await page.goto("/users");
    await page.waitForLoadState("networkidle");
    await page.locator("table tbody tr td a").first().click();
    await page.waitForURL(/\/users\/\d+$/);
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "09_member_detail.png"),
      fullPage: true,
    });
  });

  // --- 10: サーベイ一覧 ---
  test("10_survey_list", async ({ page }) => {
    await page.goto("/surveys");
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "10_survey_list.png"),
    });
  });

  // --- 11: サーベイ詳細 ---
  test("11_survey_detail", async ({ page }) => {
    await page.goto("/surveys");
    await page.waitForLoadState("networkidle");
    await page.locator("table tbody tr td a").first().click();
    await page.waitForURL(/\/surveys\/\d+$/);
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "11_survey_detail.png"),
      fullPage: true,
    });
  });

  // --- 12: タスク一覧 ---
  test("12_task_list", async ({ page }) => {
    await page.goto("/tasks");
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "12_task_list.png"),
    });
  });

  // --- 13: タスク詳細 ---
  test("13_task_detail", async ({ page }) => {
    await page.goto("/tasks");
    await page.waitForLoadState("networkidle");
    await page.locator("table tbody tr td a").first().click();
    await page.waitForURL(/\/tasks\/\d+$/);
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "13_task_detail.png"),
      fullPage: true,
    });
  });

  // --- 14: 申請・承認一覧 ---
  test("14_approval_list", async ({ page }) => {
    await page.goto("/approval_requests");
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "14_approval_list.png"),
    });
  });

  // --- 15: 承認詳細 ---
  test("15_approval_detail", async ({ page }) => {
    await page.goto("/approval_requests");
    await page.waitForLoadState("networkidle");
    await page.locator("table tbody tr td a").first().click();
    await page.waitForURL(/\/approval_requests\/\d+$/);
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "15_approval_detail.png"),
      fullPage: true,
    });
  });

  // --- 16: バッチ管理 ---
  test("16_batch_management", async ({ page }) => {
    await page.goto("/admin/batches");
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "16_batch_management.png"),
      fullPage: true,
    });
  });

  // --- 17: 操作ログ ---
  test("17_audit_logs", async ({ page }) => {
    await page.goto("/admin/audit_logs");
    await page.waitForLoadState("networkidle");
    await page.screenshot({
      path: path.join(screenshotDir, "17_audit_logs.png"),
    });
  });

  // --- 18: CSVエクスポート（SaaS一覧でボタンをホバー） ---
  test("18_csv_export", async ({ page }) => {
    await page.goto("/saases");
    await page.waitForLoadState("networkidle");
    const exportButton = page.locator("text=CSVエクスポート").first();
    await exportButton.hover();
    await page.waitForTimeout(300);
    await page.screenshot({
      path: path.join(screenshotDir, "18_csv_export.png"),
    });
  });

  // --- 19: メール通知プレビュー（letter_opener / development環境のみ） ---
  test("19_letter_opener", async ({ page }) => {
    const response = await page.goto("/letter_opener");
    if (response && response.status() === 200) {
      await page.waitForLoadState("networkidle");
      await page.screenshot({
        path: path.join(screenshotDir, "19_letter_opener.png"),
      });
    } else {
      // letter_opener is only available in development environment — skip gracefully
      test.skip(
        true,
        "letter_opener is not available in this environment (development only)"
      );
    }
  });
});
