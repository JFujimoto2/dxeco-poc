import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

test.describe("日付フィールドの曜日表示", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test("サーベイ作成画面で回答期限に曜日付き日付が表示される", async ({ page }) => {
    await page.goto("/surveys/new");

    // オーバーレイに YYYY/MM/DD (曜日) 形式で表示されている
    const display = page.locator("#deadline-display");
    await expect(display).toHaveText(/\d{4}\/\d{2}\/\d{2} \([日月火水木金土]\)/);
  });

  test("サーベイ作成画面で日付変更時にオーバーレイが更新される", async ({ page }) => {
    await page.goto("/surveys/new");

    // 日付を変更して曜日が更新されることを確認
    const dateInput = page.locator("#deadline-input");
    await dateInput.fill("2026-06-01");
    await dateInput.dispatchEvent("change");

    const display = page.locator("#deadline-display");
    // 2026-06-01 is Monday (月)
    await expect(display).toHaveText("2026/06/01 (月)");
  });
});
