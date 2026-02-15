import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

test.describe("CSVエクスポート", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test("SaaS台帳のCSVエクスポートボタンが表示されダウンロードできる", async ({
    page,
  }) => {
    await page.goto("/saases");
    const exportLink = page.locator('a:has-text("CSVエクスポート")');
    await expect(exportLink).toBeVisible();

    const response = await page.request.get("/saases/export");
    expect(response.status()).toBe(200);
    expect(response.headers()["content-type"]).toContain("text/csv");
    const body = await response.text();
    expect(body).toContain("SaaS名");
    expect(body).toContain("カテゴリ");
  });

  test("アカウント一覧のCSVエクスポートボタンが表示されダウンロードできる", async ({
    page,
  }) => {
    await page.goto("/saas_accounts");
    const exportLink = page.locator('a:has-text("CSVエクスポート")');
    await expect(exportLink).toBeVisible();

    const response = await page.request.get("/saas_accounts/export");
    expect(response.status()).toBe(200);
    expect(response.headers()["content-type"]).toContain("text/csv");
    const body = await response.text();
    expect(body).toContain("SaaS名");
    expect(body).toContain("メンバー名");
  });

  test("監査ログのCSVエクスポートボタンが表示されダウンロードできる", async ({
    page,
  }) => {
    await page.goto("/admin/audit_logs");
    const exportLink = page.locator('a:has-text("CSVエクスポート")');
    await expect(exportLink).toBeVisible();

    const response = await page.request.get("/admin/audit_logs/export");
    expect(response.status()).toBe(200);
    expect(response.headers()["content-type"]).toContain("text/csv");
    const body = await response.text();
    expect(body).toContain("日時");
    expect(body).toContain("リソース種別");
  });
});
