// Mini "linter": har .js file ka syntax check karta hai aur console.log ke
// ilawa "debugger" statements pakarta hai. Asal projects mein ESLint use hota hai.
import { readdirSync, readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { join } from "node:path";

let errors = 0;
for (const file of readdirSync("src")) {
  if (!file.endsWith(".js")) continue;
  const path = join("src", file);
  try {
    execFileSync(process.execPath, ["--check", path], { stdio: "pipe" });
  } catch (e) {
    console.error(`❌ Syntax error: ${path}\n${e.stderr}`);
    errors++;
  }
  if (/\bdebugger\b/.test(readFileSync(path, "utf8"))) {
    console.error(`❌ ${path} mein 'debugger' reh gaya hai`);
    errors++;
  }
}

if (errors) process.exit(1);
console.log("✅ Lint pass");
