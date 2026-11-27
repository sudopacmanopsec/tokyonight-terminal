# vis-cursors ✍️

A [vis](https://github.com/martanne/vis) [plugin](https://github.com/martanne/vis/wiki/Plugins) for saving cursor position per file.

Default save path is `{XDG_STATE_HOME|HOME/.local/state}/vis-cursors`.

Set a custom path with `M.path`.

Limit number of files/positions with `M.maxsize` (defaults to `1000`).

Use `M.ignore` to set a list of patterns for paths to leave cursor at top left (defaults to `{ "COMMIT_EDITMSG$", "git%-rebase%-todo$" }` ).

Each line in the file is `path,pos`, ordered by last used at the top.
