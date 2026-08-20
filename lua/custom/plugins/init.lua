-- Everything in this directory is *ours* - upstream kickstart promises not to
-- create merge conflicts under `lua/custom/`. Anything that can be expressed by
-- editing one of init.lua's documented extension points belongs there instead;
-- this directory is only for plugins and behaviour upstream doesn't ship.
--
-- NOTE: `vim.pack` loads eagerly and in order, with no dependency resolution.
-- A plugin must be added by `vim.pack.add` before anything `require`s it, so
-- the order of these calls is meaningful.

--
-- Each module is loaded under pcall so one failure (an uninstalled plugin on a
-- fresh machine, a broken update) costs that module and a notification - not
-- every module after it plus a stack trace in place of an editor.
for _, mod in ipairs {
  'clipboard', -- omarchy osc52/wayland clipboard bridge
  'omarchy', -- colorscheme, synced from the desktop theme
  'lint', -- extend kickstart's nvim-lint setup
  'ai', -- claude code + codecompanion
  'dap', -- debug adapters kickstart doesn't ship
  'git', -- diffview
  'godot', -- godot editor-server handshake
} do
  local ok, err = pcall(require, 'custom.plugins.' .. mod)
  if not ok then vim.schedule(function() vim.notify(('custom.plugins.%s failed to load:\n%s'):format(mod, err), vim.log.levels.ERROR) end) end
end
