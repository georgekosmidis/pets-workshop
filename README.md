# Pets Workshop — Training Sandbox

> ⚠️ **This is a training sandbox, not production code.** It is used for live GitHub Copilot demos and deliberately contains bugs, insecure code and synthetic data. Do not deploy it or reuse its code.

A small website for a fictional dog shelter: a [Flask](https://flask.palletsprojects.com/) + [SQLAlchemy](https://www.sqlalchemy.org/) backend and an [Astro](https://astro.build/) + [Tailwind CSS](https://tailwindcss.com/) frontend.

> On Windows, use PowerShell. The commands below are shown for PowerShell; the
> `bash` equivalents work on macOS/Linux.

## Run the server

```powershell
Set-Location app/server
py -m pip install -r requirements.txt
py utils/seed_database.py   # create and seed the local SQLite database
py app.py                   # serves on http://localhost:5100
```

## Run the client

```powershell
Set-Location app/client
npm install
npm run dev                 # serves on http://localhost:4321
```

## Run the tests

```powershell
# Server unit tests
py -m pytest app/server/test_app.py

# Client end-to-end tests
Set-Location app/client
npm run test:e2e
```

Prefer the helper scripts? From the repo root:

```powershell
.\app\scripts\seed-database.ps1
.\app\scripts\start-app.ps1
```

## Documentation catalogue

This README is the entry point. The rest of the repository's documentation:

### Getting started & demos
- [DEMO-SETUP.md](./DEMO-SETUP.md) — Demo asset map explaining the planted bugs, insecure code and synthetic data used in live Copilot demos.
- [next-steps.md](./next-steps.md) — Next steps after `azd init`: provisioning infrastructure, deploying, billing and troubleshooting.
- [copilot-cost-savings.md](./copilot-cost-savings.md) — Cost-aware GitHub Copilot usage habits that reduce AI Credit consumption.
- [LINKS.md](./LINKS.md) — Quick reference links used during the workshop.

### Application
- [app/client/README.md](./app/client/README.md) — Astro frontend starter guide and project structure.
- [app/client/e2e-tests/README.md](./app/client/e2e-tests/README.md) — Playwright end-to-end tests overview and how to run them.
- [scripts/README.md](./scripts/README.md) — Helper scripts for running and resetting the training sandbox.

### Project & community
- [CONTRIBUTING.md](./CONTRIBUTING.md) — How to contribute, prerequisites and the PR process.
- [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) — Contributor Covenant Code of Conduct.
- [SECURITY.md](./SECURITY.md) — How to report security vulnerabilities.
- [SUPPORT.md](./SUPPORT.md) — How to file issues and get help.

## License
Licensed under the MIT license. See [LICENSE](./LICENSE).

