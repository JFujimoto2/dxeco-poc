import { test, expect, Page } from "@playwright/test";
import { loginAsAdmin } from "./helpers/auth";

// Collect JS console errors per test (ignore resource loading 404s)
let consoleErrors: string[] = [];

test.beforeEach(async ({ page }) => {
  consoleErrors = [];
  page.on("console", (msg) => {
    if (msg.type() === "error") {
      const text = msg.text();
      // Ignore asset/resource 404s — only collect application JS errors
      if (!text.includes("Failed to load resource")) {
        consoleErrors.push(text);
      }
    }
  });
  await loginAsAdmin(page);
});

test.afterEach(async () => {
  expect(consoleErrors).toEqual([]);
});

/** Assert the page loaded without routing errors */
async function assertNoRoutingError(page: Page) {
  const body = await page.locator("body").textContent();
  expect(body).not.toContain("No route matches");
  expect(body).not.toContain("RoutingError");
}

// --- Dashboard ---
test("GET / (ダッシュボード)", async ({ page }) => {
  const res = await page.goto("/");
  expect(res?.status()).toBe(200);
  await expect(page.locator("body")).toContainText("SaaS管理ツール");
  await assertNoRoutingError(page);
});

// --- SaaS ---
test("GET /saases (SaaS台帳)", async ({ page }) => {
  const res = await page.goto("/saases");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /saases/:id (SaaS詳細)", async ({ page }) => {
  await page.goto("/saases");
  // Click the first SaaS name link in the table body
  await page.locator("table tbody tr td a").first().click();
  await expect(page).toHaveURL(/\/saases\/\d+$/);
  await assertNoRoutingError(page);
});

test("GET /saases/new (SaaS新規)", async ({ page }) => {
  const res = await page.goto("/saases/new");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /saases/:id/edit (SaaS編集)", async ({ page }) => {
  await page.goto("/saases");
  await page.locator("table tbody tr td.text-end a").first().click();
  await expect(page).toHaveURL(/\/saases\/\d+\/edit/);
  await assertNoRoutingError(page);
});

// --- SaaS Accounts ---
test("GET /saas_accounts (アカウント一覧)", async ({ page }) => {
  const res = await page.goto("/saas_accounts");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /saas_accounts/new (アカウント新規)", async ({ page }) => {
  const res = await page.goto("/saas_accounts/new");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /saas_accounts/:id/edit (アカウント編集)", async ({ page }) => {
  await page.goto("/saas_accounts");
  await page.locator('a[href*="/saas_accounts/"][href$="/edit"]').first().click();
  await expect(page).toHaveURL(/\/saas_accounts\/\d+\/edit/);
  await assertNoRoutingError(page);
});

// --- Users ---
test("GET /users (メンバー一覧)", async ({ page }) => {
  const res = await page.goto("/users");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /users/:id (メンバー詳細)", async ({ page }) => {
  await page.goto("/users");
  await page.locator("table tbody tr td a").first().click();
  await expect(page).toHaveURL(/\/users\/\d+$/);
  await assertNoRoutingError(page);
});

test("GET /users/:id/edit (メンバー編集)", async ({ page }) => {
  await page.goto("/users");
  await page.locator('a[href*="/users/"][href$="/edit"]').first().click();
  await expect(page).toHaveURL(/\/users\/\d+\/edit/);
  await assertNoRoutingError(page);
});

// --- Surveys ---
test("GET /surveys (サーベイ一覧)", async ({ page }) => {
  const res = await page.goto("/surveys");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /surveys/new (サーベイ作成)", async ({ page }) => {
  const res = await page.goto("/surveys/new");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /surveys/:id (サーベイ詳細)", async ({ page }) => {
  await page.goto("/surveys");
  await page.locator("table tbody tr td a").first().click();
  await expect(page).toHaveURL(/\/surveys\/\d+$/);
  await assertNoRoutingError(page);
});

// --- Tasks ---
test("GET /tasks (タスク一覧)", async ({ page }) => {
  const res = await page.goto("/tasks");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /tasks/new (タスク作成)", async ({ page }) => {
  const res = await page.goto("/tasks/new");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /tasks/:id (タスク詳細)", async ({ page }) => {
  await page.goto("/tasks");
  await page.locator("table tbody tr td a").first().click();
  await expect(page).toHaveURL(/\/tasks\/\d+$/);
  await assertNoRoutingError(page);
});

// --- Task Presets ---
test("GET /task_presets (プリセット一覧)", async ({ page }) => {
  const res = await page.goto("/task_presets");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /task_presets/new (プリセット新規)", async ({ page }) => {
  const res = await page.goto("/task_presets/new");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

// --- Approval Requests ---
test("GET /approval_requests (申請一覧)", async ({ page }) => {
  const res = await page.goto("/approval_requests");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /approval_requests/new (申請新規)", async ({ page }) => {
  const res = await page.goto("/approval_requests/new");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /approval_requests/:id (申請詳細)", async ({ page }) => {
  await page.goto("/approval_requests");
  await page.locator("table tbody tr td a").first().click();
  await expect(page).toHaveURL(/\/approval_requests\/\d+$/);
  await assertNoRoutingError(page);
});

// --- Admin ---
test("GET /admin/batches (バッチ管理)", async ({ page }) => {
  const res = await page.goto("/admin/batches");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /admin/audit_logs (操作ログ)", async ({ page }) => {
  const res = await page.goto("/admin/audit_logs");
  expect(res?.status()).toBe(200);
  await assertNoRoutingError(page);
});

test("GET /admin/audit_logs/:id (操作ログ詳細)", async ({ page }) => {
  await page.goto("/admin/audit_logs");
  await page.locator("table tbody tr td a").first().click();
  await expect(page).toHaveURL(/\/admin\/audit_logs\/\d+$/);
  await assertNoRoutingError(page);
});
