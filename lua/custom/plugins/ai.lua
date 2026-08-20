-- AI: Claude Code for agentic work, CodeCompanion for chat against the local card.
--
-- Keymap split:
--
--   <leader>a...   Claude Code   agentic edits, native diffs
--   <leader>c...   CodeCompanion chat, actions, inline
--   ga  (visual)   CodeCompanion add selection to chat
--
-- claudecode.nvim ships real defaults on <leader>a, so those are kept verbatim.
-- CodeCompanion ships no keymaps at all - its docs only *suggest* <LocalLeader>a
-- and <C-a> - so we pick keys that don't cost anything here:
--   * <LocalLeader>a would be '\a', and kickstart's neo-tree already binds '\',
--     which would put a timeoutlen delay on every tree toggle.
--   * <C-a> is vim's increment-number, which is worth more than a palette.

local function gh(repo) return 'https://github.com/' .. repo end

-- ---------------------------------------------------------------------------
-- Claude Code
-- ---------------------------------------------------------------------------
-- claudecode.nvim is a third-party but faithful implementation of the same
-- WebSocket IDE protocol Anthropic documents for the VS Code extension: a
-- loopback ws:// server on a port in 10000-65535, advertised through a lock
-- file at ~/.claude/ide/<port>.lock. It drives the `claude` CLI you are already
-- logged in to, so there's no separate token to manage.
--
-- Note the terminal stays a *native* nvim split rather than an external tmux
-- pane. The lock file is per-nvim-instance, so an external Claude survives an
-- nvim restart as a process but is orphaned from the editor until you reconnect
-- with /ide - persistence that is only half real, paid for with nvim motions
-- over the transcript. Not worth it.
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
-- Upstream's pattern also lists NvimTree, oil, minifiles and snacks_picker_list;
-- none of those are installed here, so the list is trimmed to what this config
-- actually loads.
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Claude Code: add file from the tree with <leader>as',
  group = vim.api.nvim_create_augroup('claudecode-tree', { clear = true }),
  pattern = { 'neo-tree', 'netrw' },
  callback = function(ev) vim.keymap.set('n', '<leader>as', '<cmd>ClaudeCodeTreeAdd<cr>', { buffer = ev.buf, desc = 'Claude: Add file' }) end,
})

-- ---------------------------------------------------------------------------
-- CodeCompanion (chat + inline, pointed at the local card)
-- ---------------------------------------------------------------------------
-- Two adapters, mirroring the two LLM modes of ~/models/llm-switch, which
-- arbitrates the 16GB card between llama-server, Ollama and ComfyUI - only one
-- may own it at a time. `llamacpp` is the default because llama-server is
-- llm-switch's default owner.
--
-- Neither adapter hardcodes a model name. The `openai_compatible` adapter
-- resolves schema.model.default by querying /v1/models and caching the result,
-- so nvim follows whatever the server is actually serving. A hardcoded name is
-- exactly what rotted here before: this config asked Ollama for a
-- 'qwen3-coder-agent' that no longer existed, on the service llm-switch parks
-- while llama-server holds the card.
--
-- The adapter functions are called lazily on first use, not at setup(), so
-- startup costs nothing when the card is in comfy mode and :8080 is down.
--
-- Completion inside the chat buffer, the action palette and the vim-help picker
-- all auto-detect (blink.cmp and telescope are both found) - nothing to set.
vim.pack.add {
  gh 'nvim-lua/plenary.nvim', -- already added by kickstart for telescope; harmless
  gh 'olimorris/codecompanion.nvim',
}

require('codecompanion').setup {
  adapters = {
    http = {
      -- llama-server, the primary: Qwen3.6-35B-A3B at 32k ctx on :8080.
      llamacpp = function()
        return require('codecompanion.adapters').extend('openai_compatible', {
          -- Cosmetic: the chat buffer would otherwise say "OpenAI Compatible",
          -- which says nothing about which of the two backends answered.
          formatted_name = 'llama.cpp',
          env = {
            url = 'http://127.0.0.1:8080',
            chat_url = '/v1/chat/completions',
            models_endpoint = '/v1/models',
            -- llama-server runs without --api-key, so the Authorization header
            -- is ignored - but the var still has to resolve. TERM always does.
            api_key = 'TERM',
          },
          schema = {
            -- No `model` default: let the adapter discover it from /v1/models.
            -- No `num_ctx` either; it isn't an openai_compatible knob, and the
            -- server's --ctx-size is authoritative.
            --
            -- `mapping` is not optional here. Unlike the openai adapter,
            -- openai_compatible declares only `model` in its schema, so a bare
            -- `temperature = { default = 0.2 }` resolves as a setting and is
            -- then silently dropped on the way into the request body.
            temperature = { mapping = 'parameters', type = 'number', default = 0.2 },
          },
          handlers = {
            -- Qwen3.6 is a thinking model: it returns its chain of thought in a
            -- separate `reasoning_content` field. openai_compatible captures
            -- that into `extra` but has no handler to promote it, so the whole
            -- thinking block is silently dropped and chunks that carry only
            -- reasoning arrive as empty content. deepseek solves this upstream
            -- and kimi reuses its implementation verbatim; do the same.
            --
            -- It has to be registered under the OLD flat name. Adding
            -- `handlers.response` would make uses_new_handlers() true for an
            -- adapter that is otherwise old-format, and every other handler
            -- lookup - setup, chat_output, form_messages - would then miss and
            -- return nil. See adapters/http/init.lua:8-33.
            parse_message_meta = function(self, data) return require('codecompanion.adapters.http.deepseek').handlers.response.parse_meta(self, data) end,
          },
        })
      end,

      -- Ollama, for `llm-switch ollama` mode. qwen3.5:9b is the vision-capable
      -- model, which is the reason to switch the card over to it at all.
      ollama = function()
        return require('codecompanion.adapters').extend('ollama', {
          env = { url = 'http://127.0.0.1:11434' },
          schema = {
            -- Ollama defaults num_ctx to 4k, which is far too small for
            -- anything agentic. 32k is what the 9B holds with room to spare.
            num_ctx = { default = 32768 },
            temperature = { default = 0.2 },
          },
        })
      end,
    },
  },
  interactions = {
    chat = { adapter = 'llamacpp' },
    inline = { adapter = 'llamacpp' },
    cmd = { adapter = 'llamacpp' },
  },
}

-- stylua: ignore start
vim.keymap.set({ 'n', 'v' }, '<leader>cc', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'CodeCompanion: Toggle [c]hat' })
vim.keymap.set({ 'n', 'v' }, '<leader>ca', '<cmd>CodeCompanionActions<cr>', { desc = 'CodeCompanion: [a]ction palette' })
vim.keymap.set({ 'n', 'v' }, '<leader>ci', ':CodeCompanion ', { desc = 'CodeCompanion: [i]nline prompt' })
vim.keymap.set('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', { desc = 'CodeCompanion: Add selection to chat' })
-- stylua: ignore end
vim.cmd [[cab cc CodeCompanion]]

-- Label the prefixes so which-key can explain them.
pcall(
  function()
    require('which-key').add {
      { '<leader>a', group = 'AI / Claude Code' },
      { '<leader>c', group = '[C]odeCompanion (llama-server)' },
    }
  end
)
