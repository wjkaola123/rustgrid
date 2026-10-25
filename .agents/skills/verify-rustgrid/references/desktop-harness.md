# Windows desktop harness

Use the installed Computer Use skill's full instructions. The snippets below run in the persistent `node_repl` tool, not a shell. Set `runDir` to the absolute run directory returned by Start. Save screenshots for proof, not for re-inspecting an already displayed screenshot.

Initialize and inventory:

```js
if (!globalThis.sky) {
  const { sky } = await import('@oai/sky');
  globalThis.sky = sky;
}
globalThis.windows = await sky.list_windows();
nodeRepl.write(JSON.stringify(windows));
```

Select exactly one returned window for this run's executable. Match `app` against `process:` plus the absolute binary path in the manifest; inspect returned metadata rather than reconstructing it. The main window title is `RustGrid`; the connection window title contains `New Connection` / `新建连接` or `Edit Connection` / `编辑连接`. Confirm SQLite from the selected engine and the database-file form, not an assumed engine name in the window title. Re-inventory for owned secondary windows.

```js
globalThis.matches = windows.filter(w => /RustGrid\.exe$/i.test(w.app) && w.title === 'RustGrid');
if (matches.length !== 1) throw new Error('Expected one RustGrid main window; inspect inventory');
globalThis.targetWindow = await sky.get_window({id: matches[0].id, app: matches[0].app});
await sky.activate_window({window: targetWindow});
globalThis.state = await sky.get_window_state({window: targetWindow, include_screenshot: true, include_text: true});
globalThis.targetWindow = state.window;
nodeRepl.write(JSON.stringify(state.accessibility));
```

Stop and inspect the displayed screenshot/tree. In the next cell, perform **one** input and refresh. Select one of these API forms, replacing arguments using the latest observation:

```js
await sky.click({window: state.window, element_index: indexFromCurrentTree});
// Or, when the control has no accessible target:
await sky.click({window: state.window, screenshotId: state.screenshots[0].id, x: observedX, y: observedY});
// Double-click uses the same click API with click_count: 2.
// Right-click uses mouse_button: 'right'.
// Keyboard and text input are separate actions:
await sky.press_key({window: state.window, key: 'Control_L+r'});
await sky.type_text({window: state.window, text: sqlText});
```

Each line above is an alternative action example, not a batch. After **each** chosen action:

```js
globalThis.state = await sky.get_window_state({window: targetWindow, include_screenshot: true, include_text: true});
globalThis.targetWindow = state.window;
nodeRepl.write(JSON.stringify(state.accessibility));
```

Verify focus before typing into the alias/path fields or SQL editor. If the accessibility focus is absent, use the current screenshot to locate and click the editable area, refresh, and verify the caret/active editor. Use `press_key` for Enter/Tab and shortcuts. Never reuse coordinates or indexes from a prior state. A coordinate obscured by another window requires activation and a new observation before retrying once.

An immediate snapshot can precede GPUI's next painted frame. When the expected selection, text or loading result has not appeared yet, observe again before choosing another action; do not repeat typing merely because the first screenshot is stale. The accessibility focus may remain on the native window frame while a GPUI editor visibly owns the caret. Save & Connect closes the separate form window: capture the pre-action form, click once, then re-inventory and bind the main window for the post-action screenshot. A refresh error on the now-closed form does not mean the save action failed.

Evidence setup: first set `globalThis.runId` to the RunId chosen in Launch; the following directory must equal Start's returned `runRoot`.

```js
globalThis.fs = await import('node:fs/promises');
globalThis.runDir = 'C:/project/rustgrid/target/verification/' + runId;
globalThis.record = async function(name, feature, action, assertion) {
  if (!/^[a-z0-9-]+$/.test(name)) throw new Error('Use a safe artifact stem');
  const artifacts = [];
  for (const [i, shot] of (state.screenshots || []).entries()) {
    const match = /^data:(image\/(?:png|jpeg));base64,(.*)$/s.exec(shot.url);
    if (!match) throw new Error('Unsupported screenshot MIME');
    const ext = match[1] === 'image/png' ? 'png' : 'jpg';
    const file = `${name}-${i}.${ext}`;
    await fs.writeFile(`${runDir}/${file}`, Buffer.from(match[2], 'base64'));
    artifacts.push(file);
  }
  await fs.writeFile(`${runDir}/${name}.accessibility.json`, JSON.stringify(state.accessibility, null, 2));
  await fs.appendFile(`${runDir}/actions.jsonl`, JSON.stringify({time: new Date().toISOString(), feature, action, assertion, window: state.window, artifacts}) + '\n');
};
```

Call `await record('connection-saved', 'connection-create', 'Save & Connect', 'Fresh tree shows verify-sqlite connected')` with the corresponding current screenshot. Record a before-state as well. Keep assertions tied to what was actually inspected; a logging helper cannot assert UI correctness by itself. `accessibility: null` is a capability limitation, not a failed screen capture. Do not print raw screenshot URLs or user profile/secret contents.
