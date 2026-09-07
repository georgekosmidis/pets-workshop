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

## License

Licensed under the MIT license. See [LICENSE](./LICENSE).
