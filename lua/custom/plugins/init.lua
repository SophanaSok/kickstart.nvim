-- Everything in this directory is *ours* - upstream kickstart promises not to
-- create merge conflicts under `lua/custom/`. Anything that can be expressed by
-- editing one of init.lua's documented extension points belongs there instead;
-- this directory is only for plugins and behaviour upstream doesn't ship.
--
-- NOTE: `vim.pack` loads eagerly and in order, with no dependency resolution.
-- A plugin must be added by `vim.pack.add` before anything `require`s it, so
-- the order of these calls is meaningful.

require 'custom.plugins.omarchy' -- colorscheme, synced from the desktop theme
require 'custom.plugins.lint' -- extend kickstart's nvim-lint setup
require 'custom.plugins.ai' -- claude code + codecompanion
require 'custom.plugins.dap' -- debug adapters kickstart doesn't ship
require 'custom.plugins.git' -- diffview
require 'custom.plugins.godot' -- godot editor-server handshake
