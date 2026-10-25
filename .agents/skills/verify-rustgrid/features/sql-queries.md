# SQL queries

A user chooses a connection/database, enters SQL, executes it, and inspects result sets or an error. Fixture setup uses that same editor path.

## Sub-features

- `query-open`: open a query through New Query and separately the default Ctrl+Q command.
- `query-fixture`: execute the fixture and observe 205 rows with IDs 1 through 205.
- `query-run`: execute a SELECT using Run and separately Ctrl+R.
- `query-selection`: run only selected SQL with Ctrl+Shift+R; separately check the advertised Ctrl+Enter binding for the regression below.
- `query-error`: display an invalid-SQL error and recover with a valid SELECT.

## How to get to it (user POV)

- Main toolbar **New Query / 新建查询** after selecting the connected SQLite node/database.
- Default **Ctrl+Q** creates a query tab; the **Queries / 查询** main area also offers **New Query**.
- The query toolbar's **Run / 运行** button executes the selection when one exists, otherwise the entire editor. Default **Ctrl+R** runs SQL; **Ctrl+Enter / Ctrl+Shift+R** invoke Run Selected. Focus must be inside the query editor.

## Driving it with Windows Computer Use

Preconditions: Doctor passes; `verify-sqlite` is connected to the manifest's run-local database; the fixture has not been applied to that file yet.

- **Open.** Click the connected tree node, refresh, then click New Query. Confirm a new editor tab and the connection/database selectors. If the database is not preselected, choose the SQLite file's database in its visible selector. Capture the context before entering SQL. Test Ctrl+Q separately with `sky.press_key({window: state.window, key: 'Control_L+q'})` and observe another query tab.
- **Seed through SQL.** Read `.agents/skills/verify-rustgrid/assets/fixture.sql` as text using the shell or `fs.readFile`. Click inside the observed editor, refresh and confirm focus, then `sky.type_text({window: state.window, text: fixtureSql})`. Refresh, capture SQL and context, then click Run. Wait for the running state to finish. Inspect Info and the final result tab: `total=205`, `first_id=1`, `last_id=205`. If needed click the final **Result** tab; multiple statements can produce separate results. Confirm the SQLite file exists and later open the table through the browser as the independent read path.
- **Read result.** In the editor, use Ctrl+A, refresh, then type `SELECT id, label, score, note FROM verification_items WHERE id IN (1, 2, 205) ORDER BY id;` in a separate cell. Run via the button. Require exactly 3 rows, labels `item-001`, `item-002`, `item-205`, scores `1.25`, `2.5`, `256.25`. Repeat with the editor focused and `sky.press_key({window: state.window, key: 'Control_L+r'})`; capture the resulting state for each entry point.
- **Selection.** Replace the editor text with two lines: `SELECT 42 AS selection_marker;` followed by `SELECT * FROM missing_verification_table;`. Use `Control_L+Home`, refresh, then `Shift_L+End` and refresh to select only the first line. Capture that highlight. `sky.press_key({window: state.window, key: 'Control_L+Shift_L+r'})` must produce `selection_marker=42` without the missing-table error. Separately test the advertised `Control_L+Return` binding and report its own outcome. The toolbar should read Run Selected while a selection exists.
- **Error and recovery.** Run `SELECT * FROM missing_verification_table;` with no selection. Require a visible missing-table error/Info message, then replace with `SELECT COUNT(*) AS total FROM verification_items;` and run. Require `total=205`, proving the editor remains usable. Do not treat a stale earlier result grid as the outcome of the failed query.

## Gotchas

- The actual editor selection governs toolbar behavior. Clear selections before testing whole-script execution, and capture selected SQL when testing selection-only execution.
- Key bindings are configurable; the listed defaults apply to the fresh synthetic config. A grid's F5 refresh is unrelated to query Run.
- Apply `fixture.sql` once per fresh database: it intentionally fails on a duplicate table instead of silently reusing unknown state.
- Known finding in the validated 0.0.15 build: Ctrl+Enter replaced selected SQL with a newline instead of executing it. Ctrl+Z restored the text; Ctrl+Shift+R then correctly returned 42. Keep the Ctrl+Enter result failed until a later real UI run proves it fixed; do not count the working alternative as proof for it.
- DDL or INSERT success alone is insufficient: check the SELECT result and reopen the table. SQLite success does not establish another engine's SQL dialect behavior.
