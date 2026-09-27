-- [[ Formatting ]]
-- conform.nvim runs formatters on demand only: autosave writes every second, formatting on save
-- would reflow the code while typing.
vim.pack.add({ 'https://github.com/stevearc/conform.nvim' })

-- Web projects: the first formatter configured in the project wins (oxfmt, biome or prettier),
-- taken from the project's node_modules when installed there. Nothing runs in projects without
-- one of their config files (not even the language server's formatting), so repos that do not
-- use them never get reformatted.
local web = { 'oxfmt', 'biome', 'prettier', stop_after_first = true, lsp_format = 'never' }
local prettier_only = { 'prettier', lsp_format = 'never' }

require('conform').setup({
  formatters_by_ft = {
    javascript = web,
    javascriptreact = web,
    typescript = web,
    typescriptreact = web,
    json = web,
    jsonc = web,
    css = web,
    scss = web,
    graphql = web,
    html = prettier_only,
    yaml = prettier_only,
    markdown = prettier_only,
    lua = { 'stylua' },
    sh = { 'shfmt' },
    bash = { 'shfmt' },
    fish = { 'fish_indent' },
    python = { 'ruff_organize_imports', 'ruff_format' },
    rust = { 'rustfmt' },
  },
  formatters = {
    oxfmt = { require_cwd = true },
    biome = { require_cwd = true },
    prettier = { require_cwd = true },
  },
  -- Without a usable formatter, fall back to the language server's formatting (taplo, jsonls...)
  default_format_opts = { lsp_format = 'fallback' },
})

vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format({ async = true }) end, { desc = '[F]ormat buffer or selection' })
