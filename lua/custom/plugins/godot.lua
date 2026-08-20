-- Godot integration.
--
-- The LSP half needs no code: nvim-lspconfig ships an upstream `gdscript`
-- config that connects over TCP to the *running* Godot editor (127.0.0.1:6005,
-- overridable with $GDScript_Port), and init.lua's `servers` table enables it.
-- Godot must be open for GDScript LSP to attach - that's by design.
--
-- This file handles the other direction: letting Godot open files in the nvim
-- you already have running, via Neovim's client-server mode. We start a server
-- on a fixed socket when nvim is launched inside a Godot project, and
-- ~/.local/bin/godot-nvim (set as Godot's external editor) talks to it.

local sock = (vim.env.XDG_RUNTIME_DIR or '/tmp') .. '/nvim-godot.sock'

local function in_godot_project() return vim.fs.find('project.godot', { upward = true, path = vim.fn.getcwd(), type = 'file' })[1] ~= nil end

if in_godot_project() then
  -- serverstart errors if the socket is already bound by a live nvim; that's
  -- fine, it just means another instance owns the Godot handshake.
  pcall(vim.fn.serverstart, sock)
end
