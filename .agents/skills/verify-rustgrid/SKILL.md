---
name: verify-rustgrid
description: Verify RustGrid's real desktop UI for connection management, table browsing, and SQL queries; collect screenshots and persistent-state evidence using an isolated SQLite session on Windows.
---

# Verify RustGrid

Read [the feature map](features/README.md), then the requested feature recipes. Run the actual desktop application through Windows Computer Use. The app is native GPUI, with no DOM, CDP port, HTTP control API, or application CLI. Cargo tests complement UI proof; they do not establish user-visible behavior.

## Launch

From the repository root, obey `AGENTS.md`. On this Windows host:

```powershell
./.agents/skills/verify-rustgrid/scripts/build.ps1
```

Require a successful exit before launching. The helper selects the portable 64-bit compiler when available, runs `cargo fmt --all` then `cargo build` with GNU Rust and four jobs, and saves `target/verification/build.log`. If only the incompatible 32-bit MinGW is on PATH, follow [Windows build setup](references/windows-build.md) to provision the project-local compiler. Debug builds require no `fxc.exe`. This helper expects `target/debug/RustGrid.exe`; custom Cargo target directories require adapting and revalidating the helper.

Choose a fresh run ID; keep `$verifyRun` for all calls in this run:

```powershell
$verifyRun = 'ui-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
./.agents/skills/verify-rustgrid/scripts/session.ps1 -Action Start -RunId $verifyRun
```

The returned manifest names the PID, binary hash, configuration directory, and absolute `database` path. Start creates an empty SQLite file at that path because the driver opens existing files (`create_if_missing(false)`); it creates no table/data or saved profile. Evidence lives in `target/verification/<RunId>/`, which is gitignored through `/target`.

The helper refuses an existing RustGrid process. Windows' `RustGrid.SingleInstance` mutex prevents concurrent app instances even with different profiles. `ConfigStore::new` uses the Windows Known Folder roaming path plus `rustgrid/config`; changing `APPDATA` does not isolate it. While the app is closed, the helper temporarily moves that directory to sibling `config.verify-original`, creates a marked empty configuration, and launches the binary. Cleanup restores the original directory intact. Until cleanup, do not manually open another RustGrid or run another verification session. Existing profiles and secrets are never fixture input or evidence.

Read `session.json` before recovery after an interrupted turn. If an unfinished backup/marker exists, finish that run's cleanup before starting another. The helper preserves ambiguous recovery state and reports an error instead of overwriting it.

Ready means Doctor succeeds **and** a fresh desktop snapshot shows the RustGrid main window with its New Connection toolbar and empty connection tree. Launch returning a PID is not readiness.

The desktop must be unlocked. Doctor can pass while Windows is locked: it proves process/window ownership, not that UI input is possible. If activation fails, refresh window selection and inspect one snapshot. If that snapshot is the Windows lock screen, stop UI input, request local unlock, and clean up the attempted session through the shell. Resume from a fresh session after the user unlocks; never interact with the lock screen.

## Doctor

Run this single read-only health check before driving and whenever input behaves unexpectedly:

```powershell
./.agents/skills/verify-rustgrid/scripts/session.ps1 -Action Doctor -RunId $verifyRun
```

It checks the recorded PID, start time, executable path/hash, configuration owner marker, and presence of a main window. Use the returned hash with the build log and `git rev-parse HEAD` to identify the build. Inspect `stdout.log` and `stderr.log` on failure. A missing window during startup can be retried after a fresh window inventory; a process that exits immediately may have hit the single-instance lock.

## Drive

Read the installed `computer-use` skill and its guidance/API/confirmation references before controlling Windows. Use its `node_repl` + `@oai/sky` interface, not shell-based UI automation. [Desktop harness](references/desktop-harness.md) contains the exact initialization, observation, input, and evidence calls.

Use current accessible names/indexes where available. GPUI custom controls may expose no useful accessibility tree; use screenshot-derived coordinates in that case. GPUI element IDs in source are implementation identifiers, not UI Automation selectors. After each action, refresh the state before choosing the next target. Connection forms are separate OS windows; refresh `sky.list_windows()` when they open or close.

Follow the three mapped recipes in order for a full baseline: [connection management](features/connections.md), [SQL queries](features/sql-queries.md), then [table browsing](features/table-browsing.md). The SQL recipe creates the disposable table used by browsing. No database server, password, or network authentication is required. The application does check for updates on startup, so a local SQLite test is not an offline/network-free run; leave update/download controls alone.

## Evidence

Capture the entry action and resulting state, with feature IDs and entry points in `actions.jsonl`; save before/after screenshots in their returned format (JPEG on the validated host) and accessibility text when available. See the harness's `record` function. Write `report.md` in the run directory with commit/worktree identity, build outcome, binary hash, fixture path, assertions, artifact names, and explicit passed/failed/blocked/not-run statuses for each entry point exercised. Never turn source inspection or another entry point's success into UI proof.

Connection-save proof includes a read-only inspection of the **synthetic** `connections.json` name, driver, and database path. Query mutation proof includes the visible result plus a second read path (reopen/refresh the table or run an independent SELECT); merely displaying SQL text is insufficient. Screenshots must show the connection/database context. Distinguish SQL NULL from an empty string using `IS NULL` and `length(note)` when the grid representation is ambiguous.

Exercise the real user controls. Do not call internal setters, modify profile JSON to simulate saving, or replace driver calls with mocks. `assets/fixture.sql` is entered through the query editor, so its effects also exercise the SQL execution path.

## Cleanup

After success **and every failed attempt**, run:

```powershell
./.agents/skills/verify-rustgrid/scripts/session.ps1 -Action Cleanup -RunId $verifyRun
```

The helper stops only the recorded PID after matching its executable and start time; it never kills by process name. It archives the marked synthetic configuration as `scratch-config/` under the run, then restores the user's original directory. It preserves the SQLite fixture, screenshots, action log, reports, and stdout/stderr for inspection. It performs no recursive deletion. A reused PID or lost ownership marker blocks automatic cleanup; preserve both directories and report the exact recovery error.

Confirm `session.json` says `cleaned`, the recorded process is gone, and the report plus cited screenshots still exist. A cleanup failure is an incomplete run, even if the UI assertions passed. Fixture creation/editing is confined to the run directory. Delete/drop/truncate actions are outside this baseline; follow the host's action-time confirmation rules if specifically requested later.

## Helpers

`scripts/build.ps1` builds with the checked 64-bit toolchain. `scripts/session.ps1` implements Start, Doctor, and Cleanup as shown above. Run these using PowerShell (`pwsh -File` also works); they require no installed module. `assets/fixture.sql` creates 205 known rows through the UI. Read only the selected files in `features/` for behavior-specific steps.

This packaged launch/isolation helper is Windows-only. On macOS/Linux, report `verifier-blocked` for this recipe until a native launch/isolation and desktop-control path has been established. In particular, macOS accessibility is intentionally disabled in `main.rs`; never claim Windows results cover another OS or a network driver.

Use `maintain-verification-skill` when app entry points, labels, key bindings, or lifecycle behavior change. The latest [validation record](references/validation.md) distinguishes executed checks from unproved recipes.
