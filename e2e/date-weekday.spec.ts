import { test, expect } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

test.describe("日付フィールドの曜日表示", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test("サーベイ作成画面で回答期限に曜日が表示される", async ({ page }) => {
    await page.goto("/surveys/new");

    // date input に値が入っている
    const dateInput = page.locator("#deadline-input");
    const dateValue = await dateInput.inputValue();
    expect(dateValue).toBeTruthy();

    // サーバーサイドで曜日が表示されている
    const weekdaySpan = page.locator("#deadline-weekday");
    await expect(weekdaySpan).toHaveText(/\([日月火水木金土]\)/);
  });

  test("サーベイ作成画面で日付変更時に曜日が更新される", async ({ page }) => {
    await page.goto("/surveys/new");

    // 日付を 2026-03-01 (日曜日) に変更
    const dateInput = page.locator("#deadline-input");
    await dateInput.fill("2026-03-01");
    await dateInput.dispatchEvent("change");

    const weekdaySpan = page.locator("#deadline-weekday");
    await expect(weekdaySpan).toHaveText("(日)");
  });
});
