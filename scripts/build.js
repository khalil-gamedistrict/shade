// "Build" step: src/ ko dist/ mein copy karta hai aur build-info.json likhta hai.
// Asal projects mein yahan TypeScript compile, bundling (webpack/vite), minify waghera hota hai.
import { rmSync, mkdirSync, cpSync, writeFileSync, readFileSync } from "node:fs";

const pkg = JSON.parse(readFileSync("package.json", "utf8"));

rmSync("dist", { recursive: true, force: true });
mkdirSync("dist");
cpSync("src", "dist", { recursive: true });

const info = {
  name: pkg.name,
  version: pkg.version,
  builtAt: new Date().toISOString(),
  // GitHub Actions mein yeh env variables khud set hote hain
  commit: process.env.GITHUB_SHA ?? "local",
  runNumber: process.env.GITHUB_RUN_NUMBER ?? "local",
};
writeFileSync("dist/build-info.json", JSON.stringify(info, null, 2));

console.log("✅ Build complete → dist/", info);
