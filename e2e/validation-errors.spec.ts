import { test, expect } from "@playwright/test";
import { loginAsAdmin, loginAsViewer } from "./helpers/auth";

test.describe("バリデーションエラー", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test("SaaS作成で名前が空だとHTML5バリデーションが効く", async ({ page }) => {
    await page.goto("/saases/new");
    // 名前フィールドにrequired属性があることを確認
    const nameField = page.locator('input[name="saas[name]"]');
    const isRequired = await nameField.evaluate(
      (el) => (el as HTMLInputElement).required
    );
    expect(isRequired).toBe(true);

    // 空で送信するとブラウザバリデーションにより送信されない（URLが変わらない）
    await page.locator('input[type="submit"][value="登録"]').click();
    await expect(page).toHaveURL(/\/saases\/new/);
  });

  test("承認申請で理由が空だとエラーが表示される", async ({ page }) => {
    await page.goto("/approval_requests/new");
    await page
      .locator('select[name="approval_request[request_type]"]')
      .selectOption({ index: 1 });
    // 理由を空のまま送信
    await page.locator('input[type="submit"]').click();

    // エラーが表示される（alert-danger or ページに留まる）
    await expect(page.locator(".alert-danger")).toBeVisible();
  });
});

test.describe("権限エラー", () => {
  test("viewerがSaaS作成ページにアクセスしても作成できる（権限制限なし）", async ({
    page,
  }) => {
    await loginAsViewer(page);
    await page.goto("/saases/new");
    // viewerでもSaaS作成フォームは表示される（権限制限はimport等のみ）
    await expect(page.locator('input[type="submit"]')).toBeVisible();
  });

  test("viewerが管理者ページにアクセスするとリダイレクトされる", async ({
    page,
  }) => {
    await loginAsViewer(page);
    await page.goto("/admin/batches");
    // 管理者権限が必要ですのアラートでリダイレクト
    await expect(page).toHaveURL("/");
    await expect(page.locator("body")).toContainText("管理者権限が必要です");
  });

  test("viewerがタスク作成ページにアクセスするとリダイレクトされる", async ({
    page,
  }) => {
    await loginAsViewer(page);
    await page.goto("/tasks/new");
    await expect(page).toHaveURL("/");
    await expect(page.locator("body")).toContainText("管理者権限が必要です");
  });
});
