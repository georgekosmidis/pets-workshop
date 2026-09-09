#!/usr/bin/env bash
# GitHub Copilot Enablement for TKE - environment check
# Run from the root of the workshop repository:  bash check-env.sh
# Exits 0 if you are ready, 1 if something needs fixing.

PASS=0; FAIL=0; WARN=0
ok()   { echo "  [ OK ]   $1"; PASS=$((PASS+1)); }
bad()  { echo "  [FAIL]   $1"; echo "           -> $2"; FAIL=$((FAIL+1)); }
warn() { echo "  [WARN]   $1"; echo "           -> $2"; WARN=$((WARN+1)); }

# compare dotted versions: vge 22.12.0 22.12.0 -> true
vge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }

# Detect a VS Code extension by id, covering user-installed AND bundled
# (built-in) extensions. Newer VS Code builds ship Copilot and Copilot Chat as
# built-in extensions, which 'code --list-extensions' does NOT report, so a
# CLI-only check wrongly flags them as missing. Bundled folders are often
# renamed (e.g. the 'copilot' folder is publisher 'GitHub' name 'copilot-chat'),
# so identity is read from each package.json, not the folder name.
# Args: <id> <lowercased CLI list>.
vscode_ext_present() {
  id="$1"; list="$2"
  # User-installed extensions are reported by the CLI - fast path.
  printf '%s\n' "$list" | grep -qx "$id" && return 0
  # Candidate roots for built-in (bundled) and user extension folders.
  roots=("$HOME/.vscode/extensions" "$HOME/.vscode-insiders/extensions" "$HOME/.vscode-server/extensions")
  # Resolve the 'code' launcher to locate the install's bundled extensions.
  # Some builds nest them under a hashed subdir (<dir>/<hash>/resources/app/extensions).
  codebin=$(command -v code 2>/dev/null)
  if [ -n "$codebin" ]; then
    codebin=$(readlink -f "$codebin" 2>/dev/null || echo "$codebin")
    dir=$(dirname "$codebin"); i=0
    while [ -n "$dir" ] && [ "$dir" != "/" ] && [ "$i" -lt 6 ]; do
      [ -d "$dir/resources/app/extensions" ] && { roots+=("$dir/resources/app/extensions"); break; }
      for sub in "$dir"/*/resources/app/extensions; do
        [ -d "$sub" ] && { roots+=("$sub"); break 2; }
      done
      dir=$(dirname "$dir"); i=$((i+1))
    done
  fi
  roots+=(/usr/share/code/resources/app/extensions /usr/lib/code/extensions \
          /opt/visual-studio-code/resources/app/extensions \
          /snap/code/current/usr/share/code/resources/app/extensions \
          "/Applications/Visual Studio Code.app/Contents/Resources/app/extensions")
  for root in "${roots[@]}"; do
    [ -d "$root" ] || continue
    for folder in "$root"/*/; do
      [ -d "$folder" ] || continue
      name=$(basename "$folder" | tr '[:upper:]' '[:lower:]')
      # User-installed folders are '<id>-<version>'.
      case "$name" in
        "$id"|"$id"-[0-9]*) return 0 ;;
      esac
      # Bundled folders are renamed, so match the manifest's publisher.name.
      pkg="${folder%/}/package.json"
      [ -f "$pkg" ] || continue
      pub=$(grep -oE '"publisher"[[:space:]]*:[[:space:]]*"[^"]+"' "$pkg" | head -1 | sed -E 's/.*"([^"]+)" *$/\1/')
      nm=$(grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]+"' "$pkg" | head -1 | sed -E 's/.*"([^"]+)" *$/\1/')
      [ -n "$pub" ] && [ -n "$nm" ] || continue
      combined=$(printf '%s.%s' "$pub" "$nm" | tr '[:upper:]' '[:lower:]')
      [ "$combined" = "$id" ] && return 0
    done
  done
  return 1
}

echo ""
echo "GitHub Copilot Enablement - environment check"
echo "=============================================="
echo ""

echo "Runtimes"
if command -v git >/dev/null 2>&1; then
  ok "git $(git --version | awk '{print $3}')"
else
  bad "git not found" "Install the git CLI: https://git-scm.com/downloads"
fi

NODE_FIX="Astro 6 needs Node 22.12.0 or newer. Do NOT use 'apt install nodejs' - Ubuntu ships 18.x. Use nvm:
                 curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
                 exec \$SHELL && nvm install --lts"
if command -v node >/dev/null 2>&1; then
  NV=$(node -v | tr -d 'v')
  if vge "$NV" "22.12.0"; then ok "Node.js $NV"
  else bad "Node.js $NV is too old" "$NODE_FIX"; fi
else
  bad "Node.js not found" "$NODE_FIX"
fi

if command -v npm >/dev/null 2>&1; then
  MV=$(npm -v)
  if vge "$MV" "9.6.5"; then ok "npm $MV"
  else bad "npm $MV is too old" "Needs npm 9.6.5 or newer. Run: npm install -g npm"; fi
else
  bad "npm not found" "npm ships with Node.js - reinstall Node"
fi

PY=""
# The workshop is supported on Python 3.11-3.14 (all deps publish wheels for these).
# Newer minors (3.15+) usually work but are unverified, so flag instead of rejecting.
PY_NEWER=""; PY_NEWER_V=""; PY_OLD_V=""
for c in python3 python; do
  if command -v "$c" >/dev/null 2>&1; then
    RAW=$($c -c 'import sys;print("%d.%d.%d"%sys.version_info[:3])' 2>/dev/null)
    # Keep only the first dotted-number token in case the interpreter prints noise.
    V=$(printf '%s\n' "$RAW" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    [ -z "$V" ] && continue
    if vge "$V" "3.11.0" && ! vge "$V" "3.15.0"; then
      PY=$c; ok "Python $V ($c)"; break
    elif vge "$V" "3.15.0"; then
      PY_NEWER=$c; PY_NEWER_V=$V
    else
      PY_OLD_V=$V
    fi
  fi
done
if [ -z "$PY" ]; then
  if [ -n "$PY_NEWER" ]; then
    PY=$PY_NEWER
    warn "Python $PY_NEWER_V found ($PY_NEWER) - newer than the verified range (3.11-3.14)" \
         "It will most likely work. If the dependency install below fails because a package has no wheel for Python ${PY_NEWER_V%.*}, install 3.12 alongside it and re-run this script."
  elif [ -n "$PY_OLD_V" ]; then
    bad "Python $PY_OLD_V is too old (need 3.11 or newer)" "Install Python 3.11-3.14 from https://python.org (Windows: the Microsoft Store build works)"
  else
    bad "No Python found" "Install Python 3.11-3.14 from https://python.org (Windows: the Microsoft Store build works)"
  fi
fi

echo ""
echo "Repository"
if [ -f app/server/requirements.txt ] && [ -f app/client/package.json ]; then
  ok "Running from the repository root"
else
  bad "Not in the repository root" "cd into the folder you cloned, then run this script again"
fi

if [ -d .git ]; then
  ok "This is a git clone"
else
  warn "No .git folder found" "You are probably in a downloaded ZIP. Clone the repo instead so Copilot can index it."
fi

echo ""
echo "WSL"
IN_WSL=0
if grep -qi microsoft /proc/version 2>/dev/null || [ -n "$WSL_DISTRO_NAME" ]; then
  IN_WSL=1
  ok "Running inside WSL${WSL_DISTRO_NAME:+ ($WSL_DISTRO_NAME)}"

  case "$(pwd)" in
    /mnt/[a-z]/*)
      bad "Repository is on the Windows drive ($(pwd))" \
          "Cross-filesystem access is very slow and breaks file watching. Move it into the Linux home:
                 cp -r \"\$(pwd)\" ~/ && cd ~/\$(basename \"\$(pwd)\") && bash check-env.sh" ;;
    *) ok "Repository is on the Linux filesystem" ;;
  esac

  if grep -rlq $'\r' app/scripts/*.sh 2>/dev/null; then
    bad "Shell scripts have Windows line endings (CRLF)" \
        "They will fail with 'bad interpreter: /bin/bash^M'. Fix with:
                 git config --global core.autocrlf input && rm -rf <repo> and clone again inside WSL"
  else
    ok "Shell scripts have Unix line endings"
  fi
else
  if [ "$(uname -s)" = "Linux" ] || [ "$(uname -s)" = "Darwin" ]; then
    ok "Native $(uname -s) - WSL not needed"
  else
    warn "Not running inside WSL" "On Windows this workshop expects WSL. Run this script from your WSL terminal, not PowerShell or CMD."
  fi
fi

echo ""
echo "Editor and Copilot"
if command -v code >/dev/null 2>&1; then
  ok "VS Code CLI available"
  EXT=$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')
  vscode_ext_present "github.copilot" "$EXT" \
    && ok "GitHub Copilot extension" \
    || warn "GitHub Copilot not listed by the VS Code CLI" "Newer VS Code builds bundle Copilot as a built-in extension, which the CLI does not list. Open VS Code, sign in, and confirm Copilot works. If it does not, install it from the Extensions view by searching for 'GitHub Copilot' - do not use 'code --install-extension'."
  vscode_ext_present "github.copilot-chat" "$EXT" \
    && ok "GitHub Copilot Chat extension" \
    || warn "GitHub Copilot Chat not listed by the VS Code CLI" "Newer VS Code builds bundle Copilot Chat as a built-in extension. Open the Chat view and ask a question to confirm it works. Do not run 'code --install-extension GitHub.copilot-chat' - on a bundled build it fails or, with --force, can downgrade a working setup."
  vscode_ext_present "ms-python.python" "$EXT"   && ok "Python extension"  || warn "Python extension missing"  "Recommended: code --install-extension ms-python.python"
  vscode_ext_present "ms-toolsai.jupyter" "$EXT" && ok "Jupyter extension" || warn "Jupyter extension missing" "Needed for the notebook demo: code --install-extension ms-toolsai.jupyter"
else
  warn "VS Code CLI ('code') not on PATH" "Not fatal. Open VS Code and confirm manually that Copilot and Copilot Chat are installed and signed in."
fi

echo ""
echo "Dependencies install correctly"
if [ -n "$PY" ] && [ -f app/server/requirements.txt ]; then
  if $PY -m venv .venv-check >/dev/null 2>&1; then
    VPY=".venv-check/bin/python"; [ -f "$VPY" ] || VPY=".venv-check/Scripts/python.exe"
    if "$VPY" -m pip install -q -r app/server/requirements.txt >/dev/null 2>&1; then
      ok "Python dependencies install"
      if (cd app/server && "../../$VPY" -m unittest test_app >/dev/null 2>&1); then
        ok "Backend test suite runs"
      else
        warn "Backend tests did not pass" "Not fatal on the day, but tell the trainer what error you saw."
      fi
    else
      bad "Python dependencies failed to install" "Usually a proxy or certificate issue. Send the pip error to your IT contact."
    fi
    rm -rf .venv-check
  else
    bad "Could not create a Python virtual environment" "On Debian/Ubuntu you may need: sudo apt install python3-venv"
  fi
fi

if command -v npm >/dev/null 2>&1 && [ -f app/client/package.json ]; then
  if (cd app/client && npm install --no-audit --no-fund >/dev/null 2>&1); then
    ok "Node dependencies install"
  else
    bad "Node dependencies failed to install" "Usually a proxy or registry restriction. Send the npm error to your IT contact."
  fi
fi

echo ""
echo "=============================================="
echo "  $PASS passed, $WARN warnings, $FAIL failures"
echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "  Not ready yet. Fix the FAIL items above, then run this again."
  echo "  Still stuck? Reply to the invitation with this whole output."
  echo ""
  exit 1
fi
if [ "$WARN" -gt 0 ]; then
  echo "  Ready. The warnings are optional but worth fixing before the session."
else
  echo "  Ready. Nothing to do - see you in the session."
fi
echo ""
exit 0
