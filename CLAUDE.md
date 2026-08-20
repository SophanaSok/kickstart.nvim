# kickstart.nvim (fork) — rules for agents

This repo IS the live Neovim config: `~/.config/nvim` is a symlink here. A broken
commit is a broken editor. Read `GUIDE.md` for the full mental model.

## Branches — the one rule that must not break
- **Work on `config`. Never commit to `master`.** `master` is a pristine mirror of
  `nvim-lua/kickstart.nvim`; all local changes live on `config`, rebased onto
  `master` when syncing upstream. Check `git branch --show-current` before any
  commit. If it says `master`, stop.

## Conventions
- Plugins use Neovim's built-in **`vim.pack`** (nvim ≥ 0.12), not lazy.nvim.
  Idiom: `vim.pack.add { gh 'owner/repo' }` then `require(...).setup {}`. It is
  eager and ordered — a plugin must be added before anything requires it.
  `nvim-pack-lock.json` is tracked; commit it after `:lua vim.pack.update()`.
- **`lua/kickstart/plugins/*` is upstream's.** Don't edit it (merge conflicts on
  every rebase). Local additions go in `lua/custom/plugins/*.lua`, registered in
  `lua/custom/plugins/init.lua` (pcall'd, ordered). `init.lua` is upstream's file
  edited only at its commented extension points.
- Format Lua with **stylua** (`.stylua.toml` in repo root):
  `~/.local/share/nvim/mason/bin/stylua <file>`. `collapse_simple_statement = Always`
  is in effect — match it. A PostToolUse hook in `.claude/settings.json` runs it on
  every Lua edit.
- Commit prefixes in use: `config:`, `fix:`, `docs:`, `chore:`.

## Verify before claiming done
- `nvim --headless -c quitall` prints nothing but the claudecode shutdown line.
- `~/.local/share/nvim/mason/bin/stylua --check <changed files>`.
- If you touched LSP/formatters: `:checkhealth mason`, `:checkhealth vim.lsp`.

## Context that isn't in the code
- Local LLM for CodeCompanion is llama-server on `127.0.0.1:8080`; the model name
  is auto-discovered, never hardcoded. See `lua/custom/plugins/ai.lua` header.
- The GPU holds one model at a time; `llm-switch` (in `~/models`) arbitrates.
