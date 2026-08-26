-- Copilot inline completions (ghost text) on the upstream path: the official
-- copilot-language-server (mason) driven by Neovim 0.12's built-in
-- vim.lsp.inline_completion. No copilot.lua, no cmp source, no local FIM model.
--
-- Why this exists now: GitHub Copilot Student gives unlimited code completions
-- and Next Edit Suggestions, and neither is expected to consume the plan's 200
-- AI credits. That is a completion model that costs $0 and zero VRAM - it
-- sidesteps the "no second GPU resident" rule in ~/models/CLAUDE.md entirely.
--
-- Keymap split:
--
--   <Tab>   (insert)  accept the ghost text - wired in init.lua's blink.cmp
--                     keymap so snippet-jump and NES keep priority
--   <M-]> / <M-[>     next / previous candidate
--   <leader>tc        toggle inline completion for this buffer
--
-- Sign in once with :LspCopilotSignIn (from nvim-lspconfig's lsp/copilot.lua;
-- it copies the device code to the clipboard). NES lives in sidekick.lua and
-- uses this same LSP client.
--
-- Scope: buffer text is sent to GitHub for every completion, so the client is
-- restricted to code filetypes inside a git worktree. `workspace_required` is
-- what enforces the worktree - root_markers alone would still attach with a
-- nil root_dir, i.e. to .env files, notes and commit messages.

-- nvim-lspconfig's lsp/copilot.lua supplies cmd/root_markers/init_options and
-- the sign-in commands; vim.lsp.config merges this on top. Its default
-- telemetryLevel is 'all' - turn it off.
vim.lsp.config('copilot', {
  workspace_required = true,
  -- stylua: ignore
  filetypes = { 'lua', 'rust', 'gdscript', 'gdshader', 'typescript', 'typescriptreact', 'javascript', 'javascriptreact', 'python', 'go', 'c', 'cpp', 'sh', 'bash', 'json', 'yaml', 'toml', 'html', 'css', 'markdown' },
  settings = { telemetry = { telemetryLevel = 'off' } },
})
vim.lsp.enable 'copilot'

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Copilot: enable inline completion for buffers the client attaches to',
  group = vim.api.nvim_create_augroup('custom-copilot-inline', { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or client.name ~= 'copilot' then return end
    if not client:supports_method(vim.lsp.protocol.Methods.textDocument_inlineCompletion, ev.buf) then return end

    vim.lsp.inline_completion.enable(true, { bufnr = ev.buf })

    local map = function(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc }) end
    map('i', '<M-]>', function() vim.lsp.inline_completion.select { count = 1 } end, 'Copilot: next suggestion')
    map('i', '<M-[>', function() vim.lsp.inline_completion.select { count = -1 } end, 'Copilot: previous suggestion')
    map('n', '<leader>tc', function()
      local on = not vim.lsp.inline_completion.is_enabled { bufnr = ev.buf }
      vim.lsp.inline_completion.enable(on, { bufnr = ev.buf })
      vim.notify('Copilot inline completion ' .. (on and 'on' or 'off'), vim.log.levels.INFO)
    end, '[T]oggle [C]opilot completion')
  end,
})
