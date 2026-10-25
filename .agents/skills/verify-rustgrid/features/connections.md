# Connection management

A user creates a named SQLite connection, tests it, connects, closes and reopens it, and edits the saved profile without involving a database server.

## Sub-features

- `connection-create`: create `verify-sqlite` with the run's database file and Save & Connect.
- `connection-test`: Test Connection reports success for that same file.
- `connection-reopen`: close and reopen the saved connection through its tree menu.
- `connection-edit`: edit the alias to `verify-sqlite-edited`, save, then restore `verify-sqlite`.
- `connection-cancel`: closing an unsaved connection window creates no saved connection.

## How to get to it (user POV)

- Main toolbar **New Connection / 新建连接**, then **SQLite**.
- Empty connection-tree context menu **New Connection / 新建连接…** and engine selection.
- Saved connection's context menu exposes **Open Connection / 打开连接**, **Close Connection / 关闭连接**, and **Edit Connection / 编辑连接**. Double-click the saved connection to open it.

## Driving it with Windows Computer Use

Preconditions: Doctor passes; fresh configuration; `session.json` gives an absolute `database` file path, and Start has created that empty file. No credentials or network engines are needed.

- **Create.** With the harness, `sky.click` the observed New Connection button, refresh, then click SQLite. Re-inventory windows and bind the separate SQLite connection window. Click **Connection Name / 连接名称**, refresh, then `sky.type_text({window: state.window, text: 'verify-sqlite'})`. Click **Database File / 数据库文件**, refresh, and type the manifest's absolute `database` path. Capture the populated form before submission.
- **Test.** `sky.click` the observed **Test Connection / 测试连接** control. Refresh until **Connection successful / 连接成功** replaces Testing. A nonexistent SQLite file yields `unable to open database file`; confirm Start created the exact run-local path with `Test-Path -LiteralPath` in the shell rather than changing the driver or substituting another database.
- **Save.** `sky.click` **Save & Connect / 保存并连接**. Re-inventory and bind the main window after the form closes. Require `verify-sqlite` in the connection tree, connected state, and available table/query actions. Inspect only the synthetic config's `connections.json` to confirm name, `sqlite` driver, and absolute database path. Record both UI and persistence evidence.
- **Reopen.** Right-click the observed tree connection with `sky.click({window: state.window, screenshotId: state.screenshots[0].id, x: observedX, y: observedY, mouse_button: 'right'})`. Refresh and click Close Connection. Confirm closed state. Reopen via the context menu and separately via double-click (`click_count: 2`), observing connected state after each path. Capture each entry point independently.
- **Edit.** Use the connection context menu's Edit Connection entry. Bind the form window, select the alias with `sky.press_key({window: state.window, key: 'Control_L+a'})`, refresh, and type `verify-sqlite-edited` in a separate cell. Save & Connect and prove the new tree name and saved value. Repeat to restore `verify-sqlite` for downstream recipes.
- **Cancel.** Open a fresh SQLite form from New Connection, type `verify-unsaved`, and close that form using its own close button. Verify the tree and synthetic profile file contain no `verify-unsaved` entry. Exercise the empty-tree context-menu creation path in a fresh run if a blank tree is required.

## Gotchas

- The alias and database-file inputs differ from a network connection form: SQLite has no host, port, username or password.
- New/edit connection is a separate OS window, not a main-window overlay. Capture and target the correct returned window.
- A successful Test Connection is not proof of saved-profile persistence. Require the save action and the persisted profile as well.
- Run close/reopen before creating dirty query tabs. If testing lifecycle later, save the synthetic query first (Save → query name → confirm); an unsaved-work dialog can otherwise block disconnect. Cancel that dialog while arranging persistence instead of discarding unsaved work.
- Delete is excluded from this baseline; lifecycle cleanup restores config through the shell without deleting a profile through the UI.
