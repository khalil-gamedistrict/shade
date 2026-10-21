# Build Automation with GitHub Actions — Seekhne ki Guide

## 1. Build automation kya hai?

Jab bhi aap code likhte ho, usay "ship" karne se pehle kuch kaam har dafa karne hote hain:

1. Dependencies install karna (`npm install`)
2. Code check karna (lint)
3. Tests chalana
4. Build banana (compile / bundle / zip)
5. Deploy ya release karna

**Build automation** ka matlab hai yeh sab kaam **insaan ke bajaye machine khud kare**, har dafa,
same tareeqay se. GitHub pe yeh kaam **GitHub Actions** karta hai.

Isay aksar **CI/CD** kehte hain:
- **CI (Continuous Integration):** har push/PR pe automatically lint + test + build
- **CD (Continuous Delivery/Deployment):** pass hone ke baad automatically release/deploy

## 2. Kyun zaroori hai?

| Baghair automation | Automation ke saath |
|---|---|
| "Mere computer pe to chal raha tha" 🤷 | Har dafa saaf (fresh) machine pe build hota hai |
| Tests chalana bhool gaye, bug production mein gaya | Test fail = PR merge nahi hoga ❌ |
| Release banane mein 30 min manual kaam | Ek tag push karo, baqi sab khud |
| Har developer ka alag tareeqa | Ek hi standard process, YAML file mein likha hua |

## 3. Kaise kaam karta hai? (Flow)

```
Aap: git push
        │
        ▼
GitHub dekhta hai: .github/workflows/*.yml
        │  (kya is event pe koi workflow chalni hai?)
        ▼
GitHub ek fresh VM (runner) start karta hai — ubuntu-latest
        │
        ▼
Steps ek ek kar ke chalte hain:
  checkout → setup-node → npm ci → lint → test → build → upload
        │
        ▼
Result: ✅ green tick ya ❌ red cross — commit/PR ke saath dikhta hai
```

## 4. Workflow file ke 4 bunyadi hisse

File: [.github/workflows/ci.yml](.github/workflows/ci.yml)

| Keyword | Matlab |
|---|---|
| `on:` | **Trigger** — kab chalay (push, pull_request, tag, schedule, manual) |
| `jobs:` | Kaam ke bare tukray. Har job alag VM pe chalti hai (by default parallel) |
| `runs-on:` | Kis machine pe (ubuntu / windows / macos) |
| `steps:` | Job ke andar ek ke baad ek commands |

Step do qisam ke hote hain:
- `uses:` — kisi aur ka bana hua ready-made **Action** (e.g. `actions/checkout@v4`)
- `run:` — seedhi shell command (e.g. `npm test`)

Kuch aur cheezen jo is project mein hain:
- **matrix** — same job Node 20, 22, 24 pe ek saath chalti hai
- **artifact** — build output (dist/) GitHub pe save hota hai, Actions tab se download kar sakte ho
- **secrets.GITHUB_TOKEN** — GitHub khud deta hai; apne secrets (API keys) repo
  Settings → Secrets and variables → Actions mein rakhte hain, kabhi code mein nahi
- **cache** — npm packages cache hote hain taake agli run tez ho

## 5. Is project mein kya hai

```
src/                    → asal code (calculator)
test/                   → tests (Node ka built-in test runner)
scripts/lint.js         → chhota linter
scripts/build.js        → src → dist copy + build-info.json
.github/workflows/
   ci.yml               → har push/PR pe: lint, test, build (CI)
   release.yml          → v* tag pe: build + GitHub Release (CD)
```

Local pe wahi steps chalao jo CI chalata hai:

```bash
npm ci
npm run lint
npm test
npm run build
npm start
```

## 6. GitHub pe chalane ke steps

1. GitHub pe naya **empty** repo banao (e.g. `build-automation-demo`) — README add mat karna.
2. Yahan terminal mein:
   ```bash
   git remote add origin https://github.com/<aapka-username>/build-automation-demo.git
   git push -u origin main
   ```
3. GitHub repo pe **Actions** tab kholo → "CI" workflow chalti hui dikhegi (3 jobs, matrix ki wajah se).
4. Run khatam hone pe neeche **Artifacts** mein `dist` download kar sakte ho.

## 7. Practice exercises (zaroor karo!)

**Exercise 1 — CI ko fail karwao:**
`src/calculator.js` mein `return a + b;` ko `return a - b;` kar do, commit + push.
Actions tab mein dekho: Test step ❌ red hoga, logs mein exact failing test dikhega. Phir theek kar ke push karo → ✅.

**Exercise 2 — Pull Request flow:**
```bash
git checkout -b feature/multiply
# calculator.js mein multiply function + test add karo
git commit -am "Add multiply"
git push -u origin feature/multiply
```
GitHub pe PR kholo — CI PR pe chalegi aur result PR page pe dikhega.
Bonus: Settings → Branches → branch protection rule lagao ke "CI pass hona zaroori hai" merge se pehle.

**Exercise 3 — Release banao:**
```bash
git tag v1.0.0
git push origin v1.0.0
```
"Release" workflow chalegi aur repo ke **Releases** section mein `app-v1.0.0.zip` ke saath release ban jayegi.

**Exercise 4 — Schedule add karo:**
`ci.yml` ke `on:` mein add karo:
```yaml
  schedule:
    - cron: "0 3 * * *"   # roz raat 3 baje (UTC)
```

**Exercise 5 — Lint fail karwao:**
`src/index.js` mein `debugger;` line likh ke push karo aur dekho Lint step fail hota hai.

## 8. Aagay kya seekhna hai

- `needs:` — jobs ko sequence mein chalana (pehle test, phir deploy)
- `environment:` — production deploy se pehle manual approval
- Deploy karna: GitHub Pages, Docker image → GHCR, ya server pe SSH
- Reusable workflows aur apna custom Action banana
- Official docs: https://docs.github.com/en/actions
