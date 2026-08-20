-- Omarchy theme sync.
--
-- This is the one genuinely bespoke file in the config. Omarchy ships a
-- *LazyVim* adapter and nothing else: `omarchy-theme-set` rewrites the symlink
-- at ~/.local/state/omarchy/current/theme/, whose neovim.lua returns a LazyVim
-- plugin spec that looks like
--
--   return {
--     { 'OldJobobo/retro-82.nvim', priority = 1000 },
--     { 'LazyVim/LazyVim', opts = { colorscheme = 'retro-82' } },
--   }
--
-- We read that spec, pull out the colorscheme plugin and the colorscheme name,
-- install the former with vim.pack and apply the latter. Everything is wrapped
-- in pcall: a desktop theme file must never be able to stop nvim from starting.
--
-- If this ever becomes a maintenance annoyance, delete the file and set a
-- colorscheme in init.lua instead - kickstart already installs tokyonight.

local THEME_SPEC = vim.fn.expand '~/.local/state/omarchy/current/theme/neovim.lua'
local FALLBACK = 'tokyonight-night'

local applied = nil

--- Read Omarchy's LazyVim-shaped spec and pull out what we need.
--- @return string|nil repo   e.g. 'OldJobobo/retro-82.nvim'
--- @return string|nil name   e.g. 'retro-82'
local function read_spec()
  if vim.fn.filereadable(THEME_SPEC) ~= 1 then return nil, nil end

  local ok, chunk = pcall(loadfile, THEME_SPEC)
  if not ok or not chunk then return nil, nil end

  local parsed, spec = pcall(chunk)
  if not parsed or type(spec) ~= 'table' then return nil, nil end

  local repo, name
  for _, entry in ipairs(spec) do
    if type(entry) == 'table' and type(entry[1]) == 'string' then
      if entry[1] == 'LazyVim/LazyVim' then
        -- The LazyVim entry carries the colorscheme *name*.
        if type(entry.opts) == 'table' then name = entry.opts.colorscheme end
      elseif not repo then
        -- The first non-LazyVim entry is the colorscheme *plugin*.
        repo = entry[1]
      end
    end
  end

  return repo, name
end

--- Install (if needed) and apply the current Omarchy colorscheme.
--- @param force boolean|nil  re-apply even if the name hasn't changed
local function apply(force)
  local repo, name = read_spec()

  if not name then
    if not applied then pcall(vim.cmd.colorscheme, FALLBACK) end
    return
  end
  if name == applied and not force then return end

  if repo then pcall(vim.pack.add, { 'https://github.com/' .. repo }) end

  if pcall(vim.cmd.colorscheme, name) then
    applied = name
  else
    -- Theme named something we can't load: keep nvim usable.
    pcall(vim.cmd.colorscheme, FALLBACK)
    applied = nil
  end
end

apply(true)

-- `omarchy-theme-set` flips the symlink while nvim is running. LazyVim's
-- hot-reload hooked the `LazyReload` event, which doesn't exist under vim.pack,
-- so re-check whenever the window regains focus - switching themes in Omarchy
-- goes through a picker, which takes focus away and gives it back.
vim.api.nvim_create_autocmd('FocusGained', {
  desc = 'Re-apply the Omarchy colorscheme if the desktop theme changed',
  group = vim.api.nvim_create_augroup('omarchy-theme-sync', { clear = true }),
  callback = function() pcall(apply, false) end,
})

vim.api.nvim_create_user_command('OmarchyThemeReload', function() apply(true) end, { desc = 'Re-apply the current Omarchy colorscheme' })
