import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  globalTeardown: "./e2e/global-teardown.ts",
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  retries: 0,
  workers: 1,
  reporter: "html",
  use: {
    baseURL: "http://localhost:3001",
    trace: "on-first-retry",
  },
  projects: [
    {
      name: "chromium",
      use: { browserName: "chromium" },
    },
  ],
  webServer: {
    command:
      "RAILS_ENV=test bin/rails db:prepare db:seed && RAILS_ENV=test bin/rails server -p 3001",
    url: "http://localhost:3001/up",
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
