import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";
import * as path from "path";
import * as fs from "fs";
import * as os from "os";

test.describe("CSVインポート", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test.describe("SaaS台帳", () => {
    test("インポートモーダルを開いてテンプレートDLリンクが表示される", async ({
      page,
    }) => {
      await page.goto("/saases");
      await page.locator('button:has-text("CSVインポート")').click();
      const modal = page.locator("#importModal");
      await expect(modal).toHaveClass(/show/, { timeout: 10000 });
      await expect(
        modal.locator('a:has-text("テンプレートをダウンロード")')
      ).toBeVisible();
      await expect(modal.locator('input[type="file"]')).toBeVisible();
    });

    test("テンプレートCSVをダウンロードできる", async ({ page }) => {
      const response = await page.request.get("/saases/download_template");
      expect(response.status()).toBe(200);
      expect(response.headers()["content-type"]).toContain("text/csv");
      const body = await response.text();
      expect(body).toContain("SaaS名,カテゴリ,ステータス");
    });

    test("CSVファイルをアップロードしてインポートが成功する", async ({
      page,
    }) => {
      // テスト用CSVファイルを作成
      const tmpDir = os.tmpdir();
      const csvPath = path.join(tmpDir, "saas_e2e_import.csv");
      fs.writeFileSync(
        csvPath,
        "\uFEFFSaaS名,カテゴリ,ステータス,URL,管理画面URL,説明\nE2EテストSaaS_CSV,一般,active,https://e2e-test.example.com,,E2Eテスト用\n",
        "utf-8"
      );

      await page.goto("/saases");
      await page.locator('button:has-text("CSVインポート")').click();

      const modal = page.locator("#importModal");
      await expect(modal).toHaveClass(/show/, { timeout: 10000 });

      await modal.locator('input[type="file"]').setInputFiles(csvPath);
      await modal.locator('button:has-text("インポート")').click();

      // data-turbo=false なので通常のページ遷移
      await page.waitForLoadState("networkidle");
      await expect(page).toHaveURL(/\/saases/);
      await expect(page.locator("body")).toContainText(
        "1件のSaaSをインポートしました"
      );
      await expect(page.locator("body")).toContainText("E2EテストSaaS_CSV");

      // クリーンアップ
      fs.unlinkSync(csvPath);
    });
  });

  test.describe("アカウント管理", () => {
    test("インポートモーダルを開いてテンプレートDLリンクが表示される", async ({
      page,
    }) => {
      await page.goto("/saas_accounts");
      await page.locator('button:has-text("CSVインポート")').click();
      const modal = page.locator("#importModal");
      await expect(modal).toHaveClass(/show/, { timeout: 10000 });
      await expect(
        modal.locator('a:has-text("テンプレートをダウンロード")')
      ).toBeVisible();
      await expect(modal.locator('input[type="file"]')).toBeVisible();
    });

    test("テンプレートCSVをダウンロードできる", async ({ page }) => {
      const response = await page.request.get(
        "/saas_accounts/download_template"
      );
      expect(response.status()).toBe(200);
      expect(response.headers()["content-type"]).toContain("text/csv");
      const body = await response.text();
      expect(body).toContain("SaaS名,ユーザーメール");
    });
  });
});
