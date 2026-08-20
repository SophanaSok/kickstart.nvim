-- AI: Claude Code for agentic work, CodeCompanion for chat against local Ollama.
--
-- Keymap split (both plugins keep their *documented* defaults - this is why
-- init.lua moves maplocalleader off <space>):
--
--   <leader>a...   Claude Code   agentic edits, native diffs
--   <LocalLeader>a CodeCompanion chat toggle  (localleader is '\')
--   <C-a>          CodeCompanion action palette
--   ga  (visual)   CodeCompanion add selection to chat

local function gh(repo) return 'https://github.com/' .. repo end

-- ---------------------------------------------------------------------------
-- Claude Code
-- ---------------------------------------------------------------------------
-- claudecode.nvim is a third-party but faithful implementation of the same
-- WebSocket IDE protocol Anthropic documents for the VS Code extension: a
-- loopback ws:// server on a port in 10000-65535, advertised through a lock
-- file at ~/.claude/ide/<port>.lock. It drives the `claude` CLI you are already
-- logged in to, so there's no separate token to manage.
vim.pack.add { gh 'coder/claudecode.nvim' }

require('claudecode').setup {
  -- `claude` here is a mise shim; pin the path so nvim doesn't depend on
  -- whatever PATH the parent shell happened to export.
  terminal_cmd = vim.fn.expand '~/.local/bin/claude',
  terminal = {
    -- 'native' uses a plain :terminal split. The upstream README's default
    -- pulls in folke/snacks.nvim purely for its terminal, which kickstart
    -- doesn't otherwise use.
    provider = 'native',
    split_side = 'right',
    split_width_percentage = 0.35,
    auto_insert = true,
    auto_close = true,
  },
  diff_opts = { layout = 'vertical' },
}

-- The upstream README ships these as a lazy.nvim `keys` table; vim.pack has no
-- equivalent, so they become plain keymaps. The bindings themselves are
-- unchanged from upstream.
-- stylua: ignore start
vim.keymap.set('n', '<leader>ac', '<cmd>ClaudeCode<cr>', { desc = 'Claude: Toggle' })
vim.keymap.set('n', '<leader>af', '<cmd>ClaudeCodeFocus<cr>', { desc = 'Claude: Focus' })
vim.keymap.set('n', '<leader>ar', '<cmd>ClaudeCode --resume<cr>', { desc = 'Claude: Resume' })
vim.keymap.set('n', '<leader>aC', '<cmd>ClaudeCode --continue<cr>', { desc = 'Claude: Continue' })
vim.keymap.set('n', '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', { desc = 'Claude: Select model' })
vim.keymap.set('n', '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', { desc = 'Claude: Add current buffer' })
vim.keymap.set('v', '<leader>as', '<cmd>ClaudeCodeSend<cr>', { desc = 'Claude: Send selection' })
vim.keymap.set('n', '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', { desc = 'Claude: Accept diff' })
vim.keymap.set('n', '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', { desc = 'Claude: Deny diff' })
-- stylua: ignore end

-- In a file explorer, <leader>as adds the file under the cursor instead.
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Claude Code: add file from the tree with <leader>as',
  group = vim.api.nvim_create_augroup('claudecode-tree', { clear = true }),
  pattern = { 'NvimTree', 'neo-tree', 'oil', 'minifiles', 'netrw' },
  callback = function(ev) vim.keymap.set('n', '<leader>as', '<cmd>ClaudeCodeTreeAdd<cr>', { buffer = ev.buf, desc = 'Claude: Add file' }) end,
})

-- ---------------------------------------------------------------------------
-- CodeCompanion (chat + inline, pointed at local Ollama)
-- ---------------------------------------------------------------------------
vim.pack.add {
  gh 'nvim-lua/plenary.nvim', -- already added by kickstart for telescope; harmless
  gh 'olimorris/codecompanion.nvim',
}

require('codecompanion').setup {
  adapters = {
    http = {
      ollama = function()
        return require('codecompanion.adapters').extend('ollama', {
          env = { url = 'http://127.0.0.1:11434' },
          schema = {
            model = { default = 'qwen3-coder-agent' },
            -- Ollama defaults num_ctx to 4k, which is far too small for
            -- anything agentic. The 5060 Ti has room for 64k.
            num_ctx = { default = 65536 },
            temperature = { default = 0.2 },
          },
        })
      end,
    },
  },
  interactions = {
    chat = { adapter = 'ollama' },
    inline = { adapter = 'ollama' },
    cmd = { adapter = 'ollama' },
  },
}

-- CodeCompanion's documented keymaps, verbatim.
vim.keymap.set({ 'n', 'v' }, '<C-a>', '<cmd>CodeCompanionActions<cr>', { desc = 'CodeCompanion: Actions' })
vim.keymap.set({ 'n', 'v' }, '<LocalLeader>a', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'CodeCompanion: Toggle chat' })
vim.keymap.set('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', { desc = 'CodeCompanion: Add selection to chat' })
vim.cmd [[cab cc CodeCompanion]]

-- Label the prefixes so which-key can explain them.
pcall(function()
  require('which-key').add {
    { '<leader>a', group = 'AI / Claude Code' },
    { '<LocalLeader>a', desc = 'CodeCompanion chat' },
  }
end)
