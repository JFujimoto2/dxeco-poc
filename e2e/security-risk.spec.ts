import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

test.describe("セキュリティ管理", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test("SaaS作成フォームにセキュリティ情報セクションが表示される", async ({
    page,
  }) => {
    await page.goto("/saases/new");
    await expect(page.getByText("セキュリティ情報")).toBeVisible();
    await expect(page.getByLabel("個人情報を取り扱う")).toBeVisible();
    await expect(page.getByLabel("認証方式")).toBeVisible();
    await expect(page.getByLabel("データ保存先")).toBeVisible();
  });

  test("セキュリティ属性付きSaaSを作成し詳細で確認", async ({ page }) => {
    await page.goto("/saases/new");
    await page.getByLabel("SaaS名").fill("E2Eセキュリティテスト");
    await page.getByLabel("個人情報を取り扱う").check();
    await page.getByLabel("認証方式").selectOption("password");
    await page.getByLabel("データ保存先").selectOption("overseas");
    await page.getByRole("button", { name: "登録" }).click();

    // 詳細画面でセキュリティ情報を確認
    await expect(page.getByText("セキュリティ情報")).toBeVisible();
    await expect(page.getByText("あり")).toBeVisible();
    await expect(page.getByText("パスワード")).toBeVisible();
    await expect(page.getByText("海外")).toBeVisible();
  });

  test("ダッシュボードにセキュリティリスクセクションが表示される", async ({
    page,
  }) => {
    await page.goto("/");
    const riskCard = page.locator(".card", {
      has: page.locator("text=セキュリティリスク"),
    });
    await expect(riskCard).toBeVisible();
    await expect(
      riskCard.getByText("SSO未適用", { exact: false })
    ).toBeVisible();
  });

  test("SaaS一覧に認証方式フィルターが表示される", async ({ page }) => {
    await page.goto("/saases");
    const authFilter = page.locator('select[name="auth_method"]');
    await expect(authFilter).toBeVisible();

    // SSOでフィルタリング
    await authFilter.selectOption("sso");
    await page.locator('button[type="submit"] .bi-search').click();
    await expect(page.locator("tbody")).toBeVisible();
  });

  test("SaaS一覧に部署フィルターが表示される", async ({ page }) => {
    await page.goto("/saases");
    const deptFilter = page.locator('select[name="department"]');
    await expect(deptFilter).toBeVisible();
  });

  test("アカウント管理に部署フィルターが表示される", async ({ page }) => {
    await page.goto("/saas_accounts");
    const deptFilter = page.locator('select[name="department"]');
    await expect(deptFilter).toBeVisible();
  });
});
