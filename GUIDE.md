# Neovim — user guide

Your config, what it does, and how to drive it. Lives in the repo it documents,
so it can't drift out of reach.

---

## 1. Mental model

This is **kickstart.nvim**, not a distribution. It's a single ~1000-line
`init.lua` you're meant to read and edit, plus a few optional modules.

```
~/Projects/kickstart.nvim/          <- the git repo
  init.lua                          <- upstream's file, edited at its own extension points
  lua/kickstart/plugins/            <- upstream's optional modules (all six enabled)
  lua/custom/plugins/               <- ours; upstream never touches this
  nvim-pack-lock.json               <- plugin lockfile, tracked in git
~/.config/nvim -> the repo          <- symlink, so `nvim` just works
```

### Two branches

| Branch | Contains |
|---|---|
| `master` | A pristine mirror of `nvim-lua/kickstart.nvim`. Never edit. |
| `config` | Your config. **This is the one you work on.** |

`git diff master..config` is therefore exactly "what I changed" — the reason
for the split.

### Plugin manager: `vim.pack`

Upstream migrated off lazy.nvim to `vim.pack`, Neovim's built-in manager.
Consequences worth knowing:

- **Loading is eager and ordered.** No lazy-loading, no dependency resolution.
  A plugin must be `vim.pack.add`ed before anything `require`s it, which is why
  `lua/custom/plugins/init.lua` requires its modules in a deliberate order.
- **Updating** is `:lua vim.pack.update()` — `:write` applies, `:quit` cancels.
  `:lua vim.pack.update(nil, { offline = true })` inspects without fetching.
- **Plugins live** in `~/.local/share/nvim/site/pack/core/opt/`.

---

## 2. The keymaps that matter

Leader is **`<space>`**. Forget a prefix? Press it and wait — **which-key**
shows what's available. `<leader>sk` searches every keymap by name.

### Getting around

| Key | Does |
|---|---|
| `<leader>sf` | **s**earch **f**iles |
| `<leader>sg` | **s**earch by **g**rep (live, whole project) |
| `<leader>sw` | **s**earch current **w**ord |
| `<leader><leader>` | switch buffers |
| `<leader>s.` | recent files |
| `<leader>sr` | **r**esume the last search |
| `<leader>sh` | **s**earch **h**elp — use this constantly |
| `<leader>sk` | **s**earch **k**eymaps |
| `<leader>sd` | **s**earch **d**iagnostics (whole project) |
| `\` | toggle the file tree (neo-tree) |
| `<C-h/j/k/l>` | move between windows |
| `<Esc>` | clear search highlight |

### Code (any language with an LSP attached)

| Key | Does |
|---|---|
| `grd` | **g**oto **d**efinition |
| `grr` | **g**oto **r**eferences |
| `gri` | **g**oto **i**mplementation |
| `grt` | **g**oto **t**ype definition |
| `grD` | **g**oto **D**eclaration |
| `grn` | **r**e**n**ame (project-wide) |
| `gra` | code **a**ction (quick fixes, imports) |
| `gO` | document symbols (outline of this file) |
| `gW` | workspace symbols (search all symbols) |
| `K` | hover docs |
| `<leader>th` | **t**oggle inlay **h**ints |
| `<leader>q` | put all diagnostics in the quickfix list |
| `<leader>f` | **f**ormat buffer |

> Format-on-save is **on** for every configured language. `<leader>f` is for
> when you want it early, or in a filetype that isn't auto-formatted.

### Git

| Key | Does |
|---|---|
| `]c` / `[c` | next / previous changed hunk |
| `<leader>hp` | **p**review the hunk under the cursor |
| `<leader>hs` / `<leader>hr` | **s**tage / **r**eset hunk (works on a visual range) |
| `<leader>hb` | **b**lame this line, in full |
| `<leader>hd` | **d**iff this file against the index |
| `<leader>tb` | **t**oggle inline **b**lame for every line |
| `<leader>gd` | diffview: whole working tree |
| `<leader>gm` | diffview: this branch vs `origin/HEAD` |
| `<leader>gh` | diffview: history of this file |
| `<leader>gq` | close diffview |

**Which tool when:** gitsigns for hunks while you type. Diffview to review a
whole branch or trace a file's history. `lazygit` in a terminal for staging and
committing.

### Debugging

| Key | Does |
|---|---|
| `<leader>b` | toggle **b**reakpoint |
| `<leader>B` | conditional **B**reakpoint |
| `<F5>` | start / continue |
| `<F1>` `<F2>` `<F3>` | step into / over / out |
| `<F7>` | toggle the debug UI (see the last session's output) |

### AI

Two tools, deliberately separate:

| Key | Does |
|---|---|
| **`<leader>ac`** | **Claude Code** — toggle the terminal split |
| `<leader>af` | focus the Claude split |
| `<leader>ab` | add the current **b**uffer to Claude's context |
| `<leader>as` | *(visual)* send the selection — *(in the tree)* add that file |
| `<leader>aa` / `<leader>ad` | **a**ccept / **d**eny the proposed diff |
| `<leader>ar` / `<leader>aC` | **r**esume / **C**ontinue a past session |
| `<leader>am` | select **m**odel |
| **`<leader>cc`** | **CodeCompanion** — toggle chat (local Ollama) |
| `<leader>ca` | action palette |
| `<leader>ci` | inline prompt |
| `ga` | *(visual)* add selection to the chat |

---

## 3. Claude Code in nvim

`claudecode.nvim` implements the same IDE protocol Anthropic ships for VS Code:
a loopback WebSocket server, advertised in `~/.claude/ide/<port>.lock`. The
`claude` CLI finds it automatically. It uses the CLI you're already logged into
— there's no second token.

**What you get over running `claude` in a bare terminal:**

- Your **selection and open file** are sent as context automatically. The
  transcript shows `⧉ Selected N lines from <file>`.
- **`@`-mention files** straight from the tree with `<leader>as`.
- **Diffs open as real nvim buffers.** When Claude edits a file, you get a
  vertical diff — read it, then `<leader>aa` to accept or `<leader>ad` to deny.
  Nothing is written until you accept.

**A normal loop:** `<leader>ac` to open → describe the task → Claude proposes
edits → review each diff → `<leader>aa` / `<leader>ad`.

**Check the connection:** `:ClaudeCodeStatus`.

### When to use CodeCompanion instead

CodeCompanion (`<leader>cc`) talks to **local Ollama** — `qwen3-coder-agent` at
`127.0.0.1:11434`, with context raised from Ollama's 4k default to 64k. Reach
for it when you want a fast local answer, are offline, or don't want the work
leaving the machine. Claude for agentic multi-file work; Ollama for questions.

---

## 4. Per-language notes

Every language below gets: LSP, format-on-save, and the `gr*` keymaps.

### Rust — `rust-analyzer` (pacman)
Clippy runs on save, so lints appear as diagnostics rather than at build time.
All cargo features are enabled for analysis. Debug with `<leader>b` then `<F5>`
— the launch config guesses `target/debug/<project-name>` and lets you correct it.

### TypeScript / React — `vtsls` + `tailwindcss`
Formatting uses `prettier`, preferring your **project-local** copy over the
Mason one, so per-repo config wins.

### Python — `basedpyright` + `ruff`
`ruff` handles linting and formatting (it replaces isort + black). Type checking
is `standard`, not `strict` — strict on scratch scripts is noise.

> **Watch out:** `python3` on this machine is anaconda's. Work inside a
> project `.venv` (use `uv venv`) and basedpyright will pick it up. The
> debugger is pinned to Mason's own debugpy venv, so debug sessions never
> silently run under conda base.

### C / C++ — `clangd` (pacman)
`clang-tidy` is on, with background indexing. clangd needs
**`compile_commands.json`** to understand your build — generate it with
`cmake -B build -G Ninja` (`ninja` is installed) and symlink it to the project root.

### Go — `gopls` (pacman)
`gofmt` on save; `delve` drives the debugger, already wired by kickstart.

### GDScript / Godot
GDScript LSP connects over TCP to the **running Godot editor** on port 6005 —
**Godot must be open**, that's by design, not a bug. `gdformat` on save,
`gdlint` for linting.

Godot is also set to open scripts in *this* nvim: double-click a script in Godot
and it jumps to the right line in your running instance (or opens a terminal if
none is running).

### Lua / Bash
`lua-language-server` is aware of the Neovim runtime, so editing this config
gets full completion. `stylua` formats Lua, `shfmt` formats shell, `shellcheck`
lints it.

---

## 5. Maintenance

### Update plugins
```
:lua vim.pack.update()      " review, then :write to apply
```
Then commit the lockfile: `git commit -am "chore: update plugins"`.

### Update tools
`:Mason` — `U` updates all. System tools come from pacman.

### Pull upstream kickstart
```
git fetch upstream
git checkout master && git merge --ff-only upstream/master
git checkout config && git rebase master
```
Conflicts, if any, land in `init.lua` where your edits live. That's the known
cost of forking kickstart, and the branch split keeps it visible.

### Add a language
Nearly always four edits in `init.lua`, all at commented extension points:
1. `servers` table — add the LSP
2. `ensure_installed` — if Mason should install it
3. `formatters_by_ft` — add the formatter
4. `enabled_filetypes` — turn on format-on-save
5. `parsers` — add the treesitter grammar

---

## 6. Troubleshooting

| Symptom | Check |
|---|---|
| Anything at all | `:checkhealth` |
| No LSP in this buffer | `:LspInfo` — is a client attached? Is the root dir right? |
| A tool is missing | `:Mason` |
| A plugin is missing/broken | `:lua vim.pack.update(nil, { offline = true })` |
| Formatting didn't fire | `:ConformInfo` |
| Claude won't connect | `:ClaudeCodeStatus`; confirm `~/.local/bin/claude` runs |
| GDScript has no LSP | **Is Godot open?** It hosts the server. |
| Colors didn't follow the desktop theme | `:OmarchyThemeReload` |
| Python resolving to conda | Make a project `.venv`; check `:LspInfo` root dir |
| **Everything is broken** | `NVIM_APPNAME=nvim.lazyvim.bak nvim` — your old LazyVim config, untouched |

### Undercurls look like plain underlines
In **alacritty** and **foot** only. Both force `TERM=xterm-256color` (an Omarchy
default), which understates what they can do. **ghostty** and **kitty** render
undercurls correctly. Not changed here because it's a system-wide default that
affects more than nvim.

### Full rollback
```
rm ~/.config/nvim
mv ~/.config/nvim.lazyvim.bak ~/.config/nvim
```

---

## 7. First week

Five a day, in dependency order. Don't skip ahead — each day builds on the last.

| Day | Learn |
|---|---|
| 1 | `<leader>sf` `<leader>sg` `<leader><leader>` `\` `<leader>sh` |
| 2 | `grd` `grr` `K` `<C-o>` (jump back) `<leader>q` |
| 3 | `grn` `gra` `<leader>f` `gO` `<leader>sd` |
| 4 | `]c` `[c` `<leader>hp` `<leader>hs` `<leader>hb` |
| 5 | `<leader>ac` `<leader>as` `<leader>aa` `<leader>ad` `<leader>ab` |
| 6 | `<leader>b` `<F5>` `<F2>` `<F7>` `<leader>gd` |
| 7 | `<leader>cc` `<leader>sk` `<leader>sr` `<leader>th` `:Tutor` |

If you only ever learn one: **`<leader>sk`**. It searches every keymap in the
config, so you can find the rest yourself.
