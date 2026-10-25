# RustGrid verification map

Use a successful debug build, a fresh `session.ps1 Start` run, and Doctor before driving. Start with an empty synthetic config and the existing empty SQLite file named in `session.json`. First-launch language follows the OS (Chinese on the validated host); each recipe gives both English and Chinese labels. Default shortcuts apply to the fresh configuration. There is one desktop session at a time.

Use [the desktop harness](../references/desktop-harness.md) to observe, perform one action, refresh, and save evidence. Coordinates are selected from each fresh screenshot. This is the maintained map of supported user paths, not a claim that all paths have been executed.

| Feature | Recipe | Dependencies |
| --- | --- | --- |
| Connection management | [connections.md](connections.md) | Fresh synthetic config |
| SQL execution and results | [sql-queries.md](sql-queries.md) | Connected `verify-sqlite` |
| Table browsing, paging and refresh | [table-browsing.md](table-browsing.md) | SQL fixture created |

For a full baseline run all three recipes. For a focused request, run required setup and the relevant sub-features/entry points. Record each tested entry point separately, including failures and untested branches. One successful entry point does not cover alternatives. Keep screenshots, action logs, synthetic persisted state, and `report.md` after Cleanup. Report OS and driver coverage explicitly; SQLite proof does not establish MySQL/PostgreSQL/Oracle/SQL Server/ODBC behavior.
