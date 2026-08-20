-- Debug adapters that kickstart.plugins.debug doesn't ship.
--
-- That module already sets up nvim-dap, dap-ui, mason-nvim-dap and Go (delve),
-- along with the <F1>/<F2>/<F3>/<F5>/<F7> and <leader>b keymaps. This file only
-- adds the adapters it leaves out: codelldb for Rust and C/C++, and debugpy
-- for Python. Both are installed by mason via init.lua's `ensure_installed`.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'mfussenegger/nvim-dap-python' }

local dap = require 'dap'
local mason_bin = vim.fn.stdpath 'data' .. '/mason/bin/'

-- ---------------------------------------------------------------------------
-- Rust / C / C++ via codelldb
-- ---------------------------------------------------------------------------
dap.adapters.codelldb = {
  type = 'server',
  port = '${port}',
  executable = {
    command = mason_bin .. 'codelldb',
    args = { '--port', '${port}' },
  },
}

local lldb_config = {
  {
    name = 'Launch (prompt for binary)',
    type = 'codelldb',
    request = 'launch',
    program = function()
      -- Default to the debug binary named after the project directory, which
      -- is right for a plain `cargo build` most of the time.
      local guess = vim.fn.getcwd() .. '/target/debug/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
      return vim.fn.input('Path to executable: ', vim.fn.filereadable(guess) == 1 and guess or vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
  },
}

dap.configurations.rust = lldb_config
dap.configurations.c = lldb_config
dap.configurations.cpp = lldb_config

-- ---------------------------------------------------------------------------
-- Python via debugpy
-- ---------------------------------------------------------------------------
-- NOTE: `python3` on this machine resolves to anaconda. Point dap-python at
-- mason's own debugpy venv so a debug session doesn't silently run under the
-- conda base environment.
local debugpy_python = vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python'
if vim.fn.executable(debugpy_python) == 1 then
  require('dap-python').setup(debugpy_python)
else
  -- mason hasn't installed debugpy yet; fall back so this file still loads.
  pcall(require('dap-python').setup, 'python3')
end
