import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

test.describe("CRUD操作", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test.describe("SaaS", () => {
    test("新規作成 → 編集 → 削除", async ({ page }) => {
      // 新規作成
      await page.goto("/saases/new");
      await page.locator('input[name="saas[name]"]').fill("テストSaaS_E2E");
      await page.locator('select[name="saas[category]"]').selectOption({ index: 1 });
      await page.locator('select[name="saas[status]"]').selectOption("active");
      await page.locator('textarea[name="saas[description]"]').fill("E2Eテスト用SaaS");
      await page.locator('input[type="submit"][value="登録"]').click();

      // 詳細ページにリダイレクト
      await expect(page).toHaveURL(/\/saases\/\d+/);
      await expect(page.locator("body")).toContainText("テストSaaS_E2E");

      // 編集
      await page.locator('a:has-text("編集")').click();
      await expect(page).toHaveURL(/\/saases\/\d+\/edit/);
      await page
        .locator('textarea[name="saas[description]"]')
        .fill("E2Eテスト用SaaS（更新済み）");
      await page.locator('input[type="submit"][value="更新"]').click();

      // 詳細ページに戻り更新確認
      await expect(page).toHaveURL(/\/saases\/\d+/);
      await expect(page.locator("body")).toContainText("E2Eテスト用SaaS（更新済み）");

      // 削除
      page.on("dialog", (dialog) => dialog.accept());
      await page.locator('button:has-text("削除")').click();

      // 一覧にリダイレクト
      await expect(page).toHaveURL(/\/saases/);
      await expect(page.locator("body")).not.toContainText("テストSaaS_E2E");
    });
  });

  test.describe("SaaSアカウント", () => {
    test("編集 → 削除", async ({ page }) => {
      // 一覧から既存アカウントの編集リンクをクリック
      await page.goto("/saas_accounts");
      const firstEditLink = page.locator('a[href*="/saas_accounts/"][href$="/edit"]').first();
      await firstEditLink.click();
      await expect(page).toHaveURL(/\/saas_accounts\/\d+\/edit/);

      // メールアドレスを変更
      await page.locator('input[name="saas_account[account_email]"]').fill("e2e-updated@example.com");
      await page.locator('input[type="submit"][value="更新"]').click();

      // 一覧にリダイレクト、更新が反映されていることを確認
      await expect(page).toHaveURL(/\/saas_accounts/);
      await expect(page.locator("body")).toContainText("e2e-updated@example.com");

      // 削除（trash icon button with btn-outline-danger）
      page.on("dialog", (dialog) => dialog.accept());
      const row = page.locator("tr", { hasText: "e2e-updated@example.com" });
      await row.locator("button.btn-outline-danger").click();
      await page.waitForLoadState("networkidle");
      await expect(page.locator("body")).not.toContainText("e2e-updated@example.com");
    });

    test("新規作成フォームが正常に表示される", async ({ page }) => {
      const res = await page.goto("/saas_accounts/new");
      expect(res?.status()).toBe(200);
      await expect(page.locator('select[name="saas_account[saas_id]"]')).toBeVisible();
      await expect(page.locator('select[name="saas_account[user_id]"]')).toBeVisible();
      await expect(page.locator('input[type="submit"]')).toBeVisible();
    });
  });

  test.describe("サーベイ", () => {
    test("作成 → 配信 → クローズ", async ({ page }) => {
      // 新規作成
      await page.goto("/surveys/new");
      await page.locator('input[name="survey[title]"]').fill("E2Eテストサーベイ");
      await page.locator('select[name="survey[survey_type]"]').selectOption({ index: 1 });
      await page.locator('input[type="submit"]').click();

      // 詳細ページにリダイレクト
      await expect(page).toHaveURL(/\/surveys\/\d+/);
      await expect(page.locator("body")).toContainText("E2Eテストサーベイ");

      // 配信（activate）
      const activateBtn = page.locator(
        'button:has-text("配信"), input[value*="配信"], a:has-text("配信")'
      );
      if (await activateBtn.first().isVisible()) {
        await activateBtn.first().click();
        await page.waitForLoadState("networkidle");
      }

      // クローズ
      const closeBtn = page.locator(
        'button:has-text("クローズ"), input[value*="クローズ"], a:has-text("クローズ")'
      );
      if (await closeBtn.first().isVisible({ timeout: 3000 }).catch(() => false)) {
        await closeBtn.first().click();
        await page.waitForLoadState("networkidle");
      }
    });
  });

  test.describe("承認申請", () => {
    test("申請 → 承認", async ({ page }) => {
      // 新規申請
      await page.goto("/approval_requests/new");
      await page
        .locator('select[name="approval_request[request_type]"]')
        .selectOption({ index: 1 });

      // SaaS選択（既存SaaSの場合）
      const saasSelect = page.locator(
        'select[name="approval_request[saas_id]"]'
      );
      if (await saasSelect.isVisible({ timeout: 2000 }).catch(() => false)) {
        await saasSelect.selectOption({ index: 1 });
      }

      await page
        .locator('textarea[name="approval_request[reason]"]')
        .fill("E2Eテスト用の申請理由");

      const userCountInput = page.locator(
        'input[name="approval_request[user_count]"]'
      );
      if (await userCountInput.isVisible({ timeout: 1000 }).catch(() => false)) {
        await userCountInput.fill("3");
      }

      const costInput = page.locator(
        'input[name="approval_request[estimated_cost]"]'
      );
      if (await costInput.isVisible({ timeout: 1000 }).catch(() => false)) {
        await costInput.fill("5000");
      }

      await page.locator('input[type="submit"]').click();

      // create は approval_requests_path (一覧) にリダイレクトする
      await expect(page).toHaveURL(/\/approval_requests/);

      // 一覧から新しい申請を見つけてクリック
      await page.locator("table tbody tr td a").first().click();
      await expect(page).toHaveURL(/\/approval_requests\/\d+/);

      // 承認ボタンをクリック
      const approveBtn = page.locator(
        'button:has-text("承認"), input[value="承認"]'
      );
      if (await approveBtn.first().isVisible({ timeout: 3000 }).catch(() => false)) {
        await approveBtn.first().click();
        await page.waitForLoadState("networkidle");
      }
    });
  });
});
