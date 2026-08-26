-- opencode.nvim: nvim front-end for OpenCode, the everyday agent (free cloud
-- tier by default, `local` agent when the work must stay on the card).
-- It runs the opencode TUI in a split with `--port` and talks to that server:
-- prompts get nvim-resolved context (@this, @buffer, @diagnostics, @quickfix,
-- @visible, @marks), buffers reload the moment the agent edits a file
-- (`events.reload.enabled`, on by default), and session/agent commands are
-- driven from here instead of the TUI.
--
-- Keymap split:
--
--   <leader>oo        toggle the opencode split (local helper; the plugin has no toggle)
--   <leader>oa        ask (input with @-context completion), seeded with @this
--   <leader>os        select a prompt / command / server
--   <leader>on        new session
--   <leader>oi        interrupt the running turn
--   <leader>og        cycle agent (build -> local -> ... as configured)
--   <leader>ou / od   scroll the transcript half a page up / down
--   go{motion} / goo  operator: send a range (or the line) as @this
--
-- Why the real binary: ~/.local/bin/opencode is the Omarchy mise shim, which
-- runs mise's global-install step on every launch (network, seconds of blank
-- split). Same reasoning as the pinned `claude` path in ai.lua.

vim.pack.add { { src = 'https://github.com/nickjvandyke/opencode.nvim', version = vim.version.range '1.*' } }

local bin = vim.fn.expand '~/.local/share/mise/installs/opencode/latest/opencode'
if vim.fn.executable(bin) ~= 1 then bin = 'opencode' end

vim.g.opencode_opts = {
  server = {
    -- Default is `vsplit term://opencode --port | wincmd p`; only the binary changes.
    start = function() vim.cmd('vsplit term://' .. bin .. ' --port | wincmd p') end,
  },
  select = {
    prompts = {
      godot_tests = 'Run `godot --headless res://tests/all_tests.tscn` and fix every failure; report what you changed',
      teach = 'Explain @this to a junior developer: what it does, why, and what to read next',
    },
  },
}

-- Hide the split if it is showing, re-show the buffer if it exists, else start.
local function toggle_opencode()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):match '^term://.*opencode' then return vim.api.nvim_win_hide(win) end
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf):match '^term://.*opencode' then
      vim.cmd 'vsplit'
      vim.api.nvim_win_set_buf(0, buf)
      vim.cmd 'wincmd p'
      return
    end
  end
  vim.g.opencode_opts.server.start()
end

-- stylua: ignore start
local oc = function() return require 'opencode' end
vim.keymap.set('n', '<leader>oo', toggle_opencode, { desc = '[O]penCode: T[o]ggle' })
vim.keymap.set({ 'n', 'x' }, '<leader>oa', function() oc().ask '@this: ' end, { desc = 'OpenCode: [A]sk' })
vim.keymap.set({ 'n', 'x' }, '<leader>os', function() oc().select() end, { desc = 'OpenCode: [S]elect prompt/command' })
vim.keymap.set('n', '<leader>on', function() oc().command 'session.new' end, { desc = 'OpenCode: [N]ew session' })
vim.keymap.set('n', '<leader>oi', function() oc().command 'session.interrupt' end, { desc = 'OpenCode: [I]nterrupt' })
vim.keymap.set('n', '<leader>og', function() oc().command 'agent.cycle' end, { desc = 'OpenCode: cycle a[g]ent' })
vim.keymap.set('n', '<leader>ou', function() oc().command 'session.half.page.up' end, { desc = 'OpenCode: scroll [u]p' })
vim.keymap.set('n', '<leader>od', function() oc().command 'session.half.page.down' end, { desc = 'OpenCode: scroll [d]own' })
vim.keymap.set({ 'n', 'x' }, 'go', function() return oc().operator '@this ' end, { expr = true, desc = 'OpenCode: send range as @this' })
vim.keymap.set('n', 'goo', function() return oc().operator '@this ' .. '_' end, { expr = true, desc = 'OpenCode: send line as @this' })
-- stylua: ignore end

pcall(function() require('which-key').add { { '<leader>o', group = '[O]penCode' } } end)
