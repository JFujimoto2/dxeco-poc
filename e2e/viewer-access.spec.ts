import { test, expect } from "@playwright/test";
import { loginAsViewer } from "./helpers/auth";

test.describe("viewerロールのアクセス制限", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsViewer(page);
  });

  // viewer がアクセスできるページ
  const accessiblePages = [
    { path: "/", name: "ダッシュボード" },
    { path: "/saases", name: "SaaS台帳" },
    { path: "/saas_accounts", name: "アカウント一覧" },
    { path: "/users", name: "メンバー一覧" },
    { path: "/surveys", name: "サーベイ一覧" },
    { path: "/tasks", name: "タスク一覧" },
    { path: "/approval_requests", name: "申請一覧" },
  ];

  for (const p of accessiblePages) {
    test(`${p.name} (${p.path}) にアクセスできる`, async ({ page }) => {
      const res = await page.goto(p.path);
      expect(res?.status()).toBe(200);
      const body = await page.locator("body").textContent();
      expect(body).not.toContain("No route matches");
      expect(body).not.toContain("RoutingError");
    });
  }

  // viewer がアクセスできないページ（admin専用）
  const restrictedPages = [
    { path: "/admin/batches", name: "バッチ管理" },
    { path: "/admin/audit_logs", name: "操作ログ" },
    { path: "/task_presets", name: "タスクプリセット" },
    { path: "/task_presets/new", name: "タスクプリセット新規" },
    { path: "/surveys/new", name: "サーベイ作成" },
    { path: "/tasks/new", name: "タスク作成" },
  ];

  for (const p of restrictedPages) {
    test(`${p.name} (${p.path}) はリダイレクトされる`, async ({ page }) => {
      await page.goto(p.path);
      // admin専用ページはダッシュボードにリダイレクトされる
      await expect(page).not.toHaveURL(p.path);
      // 権限エラーメッセージが表示される
      await expect(page.locator("body")).toContainText("管理者権限が必要です");
    });
  }

  // サイドバーにadmin専用リンクが表示されない
  test("サイドバーにバッチ管理・操作ログのリンクが表示されない", async ({
    page,
  }) => {
    await page.goto("/");
    const nav = page.locator("nav");
    await expect(nav.getByText("バッチ管理")).not.toBeVisible();
    await expect(nav.getByText("操作ログ")).not.toBeVisible();
  });
});
