-- sidekick.nvim: Copilot Next Edit Suggestions + a terminal for the *other*
-- AI CLIs (Cursor, Codex, optionally Antigravity). Claude stays on
-- claudecode.nvim (<leader>a) because that plugin gives real diff review;
-- opencode gets opencode.nvim (<leader>o) because that plugin talks to
-- opencode's server API. sidekick is the generic layer for CLIs that have no
-- nvim protocol of their own.
--
-- Keymap split:
--
--   <Tab>   (normal)  jump to / apply the Next Edit Suggestion
--   <C-.>             focus the CLI window (any mode)
--   <leader>kk        toggle the current CLI
--   <leader>ks        select a CLI
--   <leader>kc kx kg  toggle cursor / codex / antigravity directly
--   <leader>kt        send "this" (cursor position, or the visual selection)
--   <leader>kf        send the current file
--   <leader>kv        (visual) send the selection
--   <leader>kp        prompt library ({diagnostics}, review, tests, ...)
--   <leader>kd        detach - the tmux session keeps running
--
-- Sessions run inside tmux (installed, prefix C-Space) so an agent survives an
-- nvim restart. Unlike Claude, none of these CLIs is coupled to a per-nvim
-- lock file, so tmux persistence here is the real thing - see ai.lua for why
-- Claude is the exception. `create = 'terminal'` keeps the tmux session inside
-- an nvim window; your outer tmux keys are untouched. Detaching never kills the
-- session: `tmux ls` / `tmux kill-session -t <name>` does.
--
-- <Tab> in normal mode and <C-.> need the kitty keyboard protocol to be told
-- apart from <C-i> / to arrive at all: Alacritty >= 0.13, foot and tmux 3.7
-- with `extended-keys on` all provide it. Fallback if a terminal ever doesn't:
-- map require('sidekick').nes_jump_or_apply to <leader>kn instead.
--
-- NES needs the copilot LSP client from copilot.lua (loaded before this file).

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { { src = gh 'folke/sidekick.nvim', version = vim.version.range '2.*' } }

require('sidekick').setup {
  nes = { enabled = true },
  cli = {
    picker = 'telescope', -- telescope-ui-select already backs vim.ui.select
    win = { layout = 'right', split = { width = 80 } },
    mux = { backend = 'tmux', enabled = true, create = 'terminal' },
    tools = {
      -- Cursor CLI: plan mode first so the included usage isn't spent on a
      -- wrong first attempt. Drop `--plan` for a direct build run.
      cursor = { cmd = { 'cursor-agent', '--plan' } },
      -- Google's Antigravity CLI (optional; small weekly quota). Gemini CLI's
      -- free tier ended 2026-06-18, so sidekick's built-in `gemini` is unused.
      antigravity = { cmd = { 'agy' } },
    },
    prompts = {
      godot_tests = 'Run `godot --headless res://tests/all_tests.tscn` (exit code = failures) and fix {diagnostics}',
      teach = 'Explain {this} to a junior developer: what it does, why it is written this way, and one thing to look up',
    },
  },
}

-- The README says `tools.claude = false` disables a tool, but the code merges
-- `false or {}` into the default, so remove the entries after setup instead.
-- claudecode.nvim owns Claude; gemini's free tier is gone.
pcall(function()
  local tools = require('sidekick.config').cli.tools
  for _, name in ipairs { 'claude', 'gemini' } do
    tools[name] = nil
  end
end)

-- stylua: ignore start
local cli = function() return require 'sidekick.cli' end
vim.keymap.set('n', '<Tab>', function() if not require('sidekick').nes_jump_or_apply() then return '<Tab>' end end, { expr = true, desc = 'Sidekick: Goto/Apply Next Edit' })
vim.keymap.set({ 'n', 't', 'i', 'x' }, '<C-.>', function() cli().focus() end, { desc = 'Sidekick: Focus CLI' })
vim.keymap.set('n', '<leader>kk', function() cli().toggle() end, { desc = 'Side[k]ick: Toggle CLI' })
vim.keymap.set('n', '<leader>ks', function() cli().select() end, { desc = 'Sidekick: [S]elect CLI' })
vim.keymap.set('n', '<leader>kc', function() cli().toggle { name = 'cursor', focus = true } end, { desc = 'Sidekick: [C]ursor agent' })
vim.keymap.set('n', '<leader>kx', function() cli().toggle { name = 'codex', focus = true } end, { desc = 'Sidekick: Code[x]' })
vim.keymap.set('n', '<leader>kg', function() cli().toggle { name = 'antigravity', focus = true } end, { desc = 'Sidekick: Anti[g]ravity (Google)' })
vim.keymap.set('n', '<leader>kd', function() cli().close() end, { desc = 'Sidekick: [D]etach (tmux session keeps running)' })
vim.keymap.set({ 'n', 'x' }, '<leader>kt', function() cli().send { msg = '{this}' } end, { desc = 'Sidekick: Send [t]his' })
vim.keymap.set('n', '<leader>kf', function() cli().send { msg = '{file}' } end, { desc = 'Sidekick: Send [f]ile' })
vim.keymap.set('x', '<leader>kv', function() cli().send { msg = '{selection}' } end, { desc = 'Sidekick: Send [v]isual selection' })
vim.keymap.set({ 'n', 'x' }, '<leader>kp', function() cli().prompt() end, { desc = 'Sidekick: [P]rompt library' })
-- stylua: ignore end

pcall(function() require('which-key').add { { '<leader>k', group = 'Side[k]ick (Cursor / Codex / agy)' } } end)
