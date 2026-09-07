# Demo scripts

Helper scripts for running the training sandbox. See [`DEMO-SETUP.md`](../DEMO-SETUP.md) for the full asset map.

## `reset-demo.ps1` / `reset-demo.sh`

Restores the repository to the tagged baseline between sessions. It discards
working-tree changes, removes untracked files, deletes a live-authored
`.github/copilot-instructions.md` if one exists, and hard-resets to the
`demo-baseline` tag.

Use `reset-demo.ps1` on Windows (PowerShell) and `reset-demo.sh` on
macOS/Linux. Both behave identically.

As a safety measure it **refuses to run** when the current branch is `main`
and `origin` points at the canonical upstream (`github-samples/pets-workshop`),
so it cannot be aimed at the wrong repository by accident.

### Tag the baseline (once, before the first session)

Commit the prepared demo state, then tag it:

```powershell
git add -A
git commit -m "Prepare training demo baseline"
git tag demo-baseline
```

If you later change the intended starting state, move the tag:

```powershell
git tag -f demo-baseline
```

### Reset between sessions

From anywhere inside the repository:

```powershell
# Windows (PowerShell)
.\scripts\reset-demo.ps1
```

```bash
# macOS/Linux
bash scripts/reset-demo.sh
```
