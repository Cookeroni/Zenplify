// Pure helpers for niri's IPC event-stream. No QML/scope dependencies — every
// function takes state in and returns a value, so it stays unit-testable.
//
// niri sends newline-delimited JSON: the full workspace state up-front
// (WorkspacesChanged), then incremental updates. Each workspace carries
// id / idx (1-based, per-output) / name / output / is_active / is_focused.
// There is exactly one globally focused workspace at a time.

// Fold one parsed event into the id-keyed workspace map, mutating it in place.
// Mirrors niri's own semantics: WorkspacesChanged fully replaces the set;
// WorkspaceActivated re-points active (per output) and, if focused, focus.
function applyEvent(byId, ev) {
    if (ev.WorkspacesChanged) {
        for (var k in byId)
            delete byId[k];
        var list = ev.WorkspacesChanged.workspaces || [];
        for (var i = 0; i < list.length; i++)
            byId[list[i].id] = list[i];
        return;
    }
    if (ev.WorkspaceActivated) {
        var id = ev.WorkspaceActivated.id;
        var focused = ev.WorkspaceActivated.focused;
        var target = byId[id];
        if (!target)
            return;
        for (var key in byId) {
            var w = byId[key];
            if (w.output === target.output)
                w.is_active = (w.id === id);   // one active per output
            if (focused)
                w.is_focused = (w.id === id);  // single global focus
        }
        return;
    }
    // Window/keyboard/etc. events don't touch the workspace stack — ignored.
}

// Derive the stack for the focused output: workspaces on that output sorted by
// idx, plus the focused workspace's 0-based position within it. Returns
// { list, activeIdx, count, name, focusedId }; focusedId is -1 when unknown.
function focusedStack(byId) {
    var focused = null;
    for (var k in byId) {
        if (byId[k].is_focused) {
            focused = byId[k];
            break;
        }
    }
    if (!focused)
        return { list: [], activeIdx: -1, count: 0, name: "", focusedId: -1 };

    var stack = [];
    for (var key in byId) {
        if (byId[key].output === focused.output)
            stack.push(byId[key]);
    }
    stack.sort(function (a, b) { return a.idx - b.idx; });

    var activeIdx = 0;
    for (var i = 0; i < stack.length; i++) {
        if (stack[i].id === focused.id) {
            activeIdx = i;
            break;
        }
    }
    return {
        list: stack,
        activeIdx: activeIdx,
        count: stack.length,
        idx: focused.idx,
        name: focused.name || String(focused.idx),
        focusedId: focused.id
    };
}
