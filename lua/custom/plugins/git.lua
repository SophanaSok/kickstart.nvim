-- Git: diffview for whole-branch and file-history review.
--
-- kickstart.plugins.gitsigns already covers in-buffer hunks (stage, reset,
-- blame) and telescope covers finding things. Diffview fills the remaining gap:
-- reviewing an entire branch diff, or one file's history, as real buffers.
-- lazygit stays the tool for staging and committing.

local function gh(repo) return 'https://github.com/' .. repo end

vim.pack.add { gh 'sindrets/diffview.nvim' }

require('diffview').setup {
  enhanced_diff_hl = true,
  view = {
    merge_tool = { layout = 'diff3_mixed' },
  },
}

-- stylua: ignore start
vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<cr>', { desc = '[G]it [D]iff working tree' })
vim.keymap.set('n', '<leader>gm', '<cmd>DiffviewOpen origin/HEAD...HEAD<cr>', { desc = '[G]it diff vs [m]ain' })
vim.keymap.set('n', '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', { desc = '[G]it file [h]istory' })
vim.keymap.set('n', '<leader>gH', '<cmd>DiffviewFileHistory<cr>', { desc = '[G]it branch [H]istory' })
vim.keymap.set('n', '<leader>gq', '<cmd>DiffviewClose<cr>', { desc = '[G]it diff [q]uit' })
-- stylua: ignore end

pcall(function() require('which-key').add { { '<leader>g', group = '[G]it' } } end)
