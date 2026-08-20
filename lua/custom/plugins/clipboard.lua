-- Omarchy's remote clipboard bridge.
--
-- Without this, a yank inside tmux or over SSH never reaches the system
-- clipboard. The provider emits every copy as OSC 52 (which tmux turns into a
-- buffer and rebroadcasts to all attached clients) while still preferring the
-- local Wayland clipboard for pastes, so content copied in other apps stays
-- pasteable.
--
-- It is loaded from the omarchy-nvim package rather than copied into this repo:
-- pacman then keeps it current, and nothing lands in `lua/config/` (which is
-- gitignored, because Omarchy's migrations install into it on system upgrade).
--
-- The provider self-guards - it returns early unless it detects tmux, SSH or
-- herdr - so on a plain local session Neovim's normal clipboard is untouched.

local candidates = {
  '/usr/share/omarchy-nvim/config/lua/config/remote_clipboard.lua',
  vim.fn.stdpath 'config' .. '/lua/config/remote_clipboard.lua',
}

for _, path in ipairs(candidates) do
  if vim.fn.filereadable(path) == 1 then
    local chunk = loadfile(path)
    if chunk then
      local ok, mod = pcall(chunk)
      if ok and type(mod) == 'table' and type(mod.setup) == 'function' then
        pcall(mod.setup)
        break
      end
    end
  end
end
