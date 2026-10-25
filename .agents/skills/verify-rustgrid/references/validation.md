# Validation record

Status on 2026-10-25: **real UI baseline verified on Windows + SQLite; one shortcut check failed**. The generated skill has completed launch, Doctor, real user actions, evidence collection and cleanup. It is no longer an unexecuted draft.

Base commit: `788c27428efef00129631878b13fd77e82f81fd7`, application version 0.0.15. Existing application source and version were unchanged. This record covers this machine and SQLite; other OSes and database drivers have not been verified.

## Runtime evidence

Primary run: `target/verification/ui-20261025-unlocked/report.md`. Final-helper repeat: `target/verification/ui-20261025-repeat/report.md`. Both run directories retain JPEG screenshots, accessibility JSON, actions.jsonl, session manifests, logs and synthetic config archives after cleanup.

| Behavior | Result | Main evidence in primary run |
| --- | --- | --- |
| New Connection → SQLite → Test Connection | Passed | connection-test-passed-0.jpg |
| Save & Connect and persisted profile | Passed | connection-saved-0.jpg; scratch-config/connections.json |
| Close Connection, then double-click reopen | Passed | connection-closed-passed-0.jpg; connection-reopened-passed-0.jpg |
| Fixture entered and run through SQL editor | Passed | fixture-aggregate-passed-0.jpg: total 205, first ID 1, last ID 205 |
| Ctrl+R sample SELECT | Passed | sample-query-passed-0.jpg: IDs 1/2/205, expected labels/scores/NULLs |
| Ctrl+Shift+R selection-only execution | Passed | selection-highlighted-0.jpg; selection-ctrl-shift-r-passed-0.jpg: 42, no second-statement error |
| Ctrl+Enter selection-only execution | Failed | ctrl-enter-observed-newline-0.jpg: selected SQL replaced by newline; Ctrl+Z restored it |
| Invalid SQL error and valid-query recovery | Passed | query-error-displayed-0.jpg; query-error-recovery-passed-0.jpg |
| Table opened from object-list double-click | Passed | table-open-passed-0.jpg |
| Page size 100; page 1, page 2, last page | Passed | table-page1-passed-0.jpg; table-page2-passed-0.jpg; table-last-page-passed-0.jpg |
| F5 and grid refresh button | Passed | table-f5-passed-0.jpg; table-refresh-button-passed-0.jpg |
| Filter id = 205; disable condition and apply | Passed | filter-205-passed-0.jpg; filter-disabled-passed-0.jpg |
| Independent read-only DB inspection | Passed | database-proof.json: count 205, expected sample rows, integrity_check ok |

Not run: connection alias editing/canceling, empty-tree context-menu creation, connection context-menu reopen, Ctrl+Q, Queries-area creation, table tree/context-menu/Open Table alternatives, previous/first-page buttons, filter-row removal. These remain mapped recipes, not inferred passes.

## Final helper repeat

After correcting the initial setup, the final session.ps1 was executed in a fresh run. It automatically created an empty existing SQLite file, started the actual app, passed Doctor, and completed New Connection → SQLite → Test Connection → Save & Connect without manual file preparation. The saved profile was checked against name/driver/path. Cleanup completed; repeat-test-passed-0.jpg, repeat-save-passed-0.jpg and profile-proof.json survive.

## Build and lifecycle

- cargo fmt --all and cargo build succeeded using scripts/build.ps1, GNU Rust 1.99.1, and the checksum-verified portable x86_64 MinGW-w64 compiler. The initial build took 19m 10s. The latest log is target/verification/build.log; the initial successful log is preserved in target/verification/ui-20261025-live2/build-initial.log.
- Executable SHA-256: `13A873536737E1E0D39ED4FBD47C938C052D6BBE5C872F25C47298B50E841C49`.
- The old 32-bit GCC was not replaced; compiler PATH changes are process-local. The skill validator and PowerShell parser passed.
- Startup ticks now survive PowerShell JSON date coercion. WindowStyle Normal exposes the interactive GPUI window; Hidden did not. The real host returns JPEG screenshots and can paint a frame after the immediate post-action capture; both findings are reflected in the harness.
- SQLite requires an existing file. Start creates only that empty file; table structure and all 205 rows were created through the real SQL editor. First-launch language follows the OS and was Chinese here.
- All test processes were stopped by recorded PID/path/start ticks, and all session manifests are cleaned. The configuration root was absent before verification and is absent afterward; no original backup remains.
- Earlier lifecycle checks also restored a synthetic original config sentinel byte-for-byte (SHA-256 `1EBB6E40FB0644B65720260DE266B4704CC992D0AA6496014E9F49194331DDD5`), archived under target/verification/ui-20261025-live2/restore-sentinel-proof. No user profile or secret was used.

The Ctrl+Enter finding is an observed application shortcut issue, not a failure of the verification lifecycle. Preserve it as failed until a subsequent real UI run demonstrates a fix; the working Ctrl+Shift+R alternative does not cover it.
