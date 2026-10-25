# Table data browsing

A user locates a table, opens its data grid, pages through records and refreshes the displayed data without editing it.

## Sub-features

- `table-open`: open `verification_items` from the object list and separately the tree.
- `table-page`: change page size to 100; verify first, next and last pages of 205 rows.
- `table-refresh`: refresh through the grid control and separately the default F5 shortcut.
- `table-filter`: apply a filter for `id = 205`, then remove it to restore all rows.

## How to get to it (user POV)

- Connected SQLite node/database → **Tables / 表** object category → double-click `verification_items` in the object list, or select it and choose **Open Table / 打开表**.
- Expand the connection tree's table category → double-click the table, or use its **Open Table** context-menu entry.
- Grid footer: first/previous/page/next/last controls, page-size gear menu, and refresh. **F5** refreshes while the grid holds focus.
- Grid **Filter / 筛选** control opens the condition editor.

## Driving it with Windows Computer Use

Preconditions: Doctor passes; `verify-sqlite` connected; the SQL recipe has created `verification_items` with 205 rows.

- **Locate.** Return to the object browser, select the connected SQLite database and Tables category. Refresh the object listing if the fixture was created after it was loaded. Observe `verification_items` before trying to open it.
- **Open.** Use `sky.click` with `click_count: 2` on the observed table row. Require a data tab titled `verification_items`, columns `id`, `label`, `score`, `note`, and visible fixture rows. Capture entry and resulting grid. Separately exercise the object-list Open Table control/context menu and tree double-click/context-menu paths; record exactly which paths were used.
- **Page.** Click the footer's page-size gear and ensure **Limit Records** is checked. Click the page-size input. This custom numeric input appends digits and ignores Ctrl+A: press Backspace in separate action/refresh cells until the displayed value is empty, type `100`, then confirm with `sky.press_key({window: state.window, key: 'Return'})`. On page 1 require 100 fetched rows and first ID 1. Click the observed next-page arrow; require page 2, 100 fetched rows and first ID 101. Click last page; require page 3, 5 fetched rows, IDs 201–205, and disabled next/last controls. Return to first page and prove the range resets. Base ordering follows the integer primary key in this fixture; use the ID column/header to establish ascending order if needed.
- **Refresh.** Click the visible grid refresh control, then separately focus a data cell and `sky.press_key({window: state.window, key: 'F5'})`. Observe loading finish, intact headers, and the same fixture row count/range. Capture a fresh result after each path.
- **Filter.** Click Filter and refresh. The initial panel may already contain an enabled `id` / `=` row; use `+` only when a condition still needs adding. Set its value to `205`, then click Apply. Require exactly the row `205 / item-205`. Disable the row's checkbox (the validated path), or separately test removing it; Apply and require the unfiltered 205-row total/page structure. Select targets from each current screenshot; the filter uses custom GPUI controls.

## Gotchas

- Query results reuse grid rendering but have different paging semantics. This recipe requires the actual table tab with its table toolbar and page controls.
- The object list may be stale after DDL. Refresh that list before concluding that the table was not created.
- Selection and editable cells can consume keys. Confirm grid focus before F5; avoid opening an editor when only browsing.
- Row count in the status can describe fetched rows versus total rows. Prove page numbers, ID ranges and last-page size together; do not infer total coverage from one label.
