import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

test.describe("サイドバーナビゲーション", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  const sidebarLinks = [
    { text: "ダッシュボード", url: "/" },
    { text: "SaaS台帳", url: "/saases" },
    { text: "アカウント管理", url: "/saas_accounts" },
    { text: "メンバー", url: "/users" },
    { text: "サーベイ", url: "/surveys" },
    { text: "タスク管理", url: "/tasks" },
    { text: "申請・承認", url: "/approval_requests" },
    { text: "バッチ管理", url: "/admin/batches" },
    { text: "操作ログ", url: "/admin/audit_logs" },
  ];

  for (const link of sidebarLinks) {
    test(`サイドバー「${link.text}」→ ${link.url}`, async ({ page }) => {
      await page.goto("/");
      await page.locator("nav .nav-link").getByText(link.text, { exact: true }).click();
      await page.waitForLoadState("networkidle");
      expect(page.url()).toContain(link.url);

      const body = await page.locator("body").textContent();
      expect(body).not.toContain("No route matches");
      expect(body).not.toContain("RoutingError");
    });
  }

  test("連続ナビゲーション（全リンクを順番にクリック）", async ({ page }) => {
    await page.goto("/");

    for (const link of sidebarLinks) {
      await page.locator("nav .nav-link").getByText(link.text, { exact: true }).click();
      await page.waitForURL(`**${link.url}`, { timeout: 10000 });

      const body = await page.locator("body").textContent();
      expect(body).not.toContain("No route matches");
    }
  });
});
