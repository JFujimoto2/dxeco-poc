import { execSync } from "child_process";

export default function globalTeardown() {
  // Clean up seed data so RSpec tests can run with a clean DB
  console.log("Cleaning test database for RSpec compatibility...");
  execSync("RAILS_ENV=test bin/rails db:schema:load", {
    cwd: process.cwd(),
    stdio: "inherit",
  });
}
