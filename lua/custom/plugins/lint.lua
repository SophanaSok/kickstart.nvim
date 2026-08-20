-- Extend kickstart.plugins.lint.
--
-- That module *replaces* `lint.linters_by_ft` with a fresh table rather than
-- merging into nvim-lint's defaults - which is deliberate, since the defaults
-- reference a dozen linters that aren't installed. Because it replaced the
-- table, assigning extra filetypes into it here is safe and doesn't drag those
-- defaults back in.

local lint = require 'lint'

lint.linters_by_ft.sh = { 'shellcheck' }
lint.linters_by_ft.bash = { 'shellcheck' }
lint.linters_by_ft.gdscript = { 'gdlint' }
