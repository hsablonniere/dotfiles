-- [[ LSP ]]
-- nvim-lspconfig provides the default config of each server (command, filetypes, root markers),
-- mason installs the servers in nvim's data directory, independently of the system and mise.
vim.pack.add({
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/mason-org/mason.nvim',
  -- JSON and YAML schemas (package.json, tsconfig.json, GitHub workflows, docker-compose...)
  'https://github.com/b0o/SchemaStore.nvim',
})
require('mason').setup()

-- lspconfig server name -> mason package, false when installed outside mason
local servers = {
  -- Web
  tsc = 'tsc', -- TypeScript 7 native language server, also handles JavaScript
  html = 'html-lsp',
  cssls = 'css-lsp',
  eslint = 'eslint-lsp',
  emmet_language_server = 'emmet-language-server',
  stylelint_lsp = 'stylelint-language-server',
  css_variables = 'css-variables-language-server',
  -- Config and data
  jsonls = 'json-lsp',
  yamlls = 'yaml-language-server',
  taplo = 'taplo',
  lua_ls = 'lua-language-server',
  -- Shell and docs
  bashls = 'bash-language-server',
  fish_lsp = 'fish-lsp',
  marksman = 'marksman',
  -- DevOps and system
  dockerls = 'dockerfile-language-server',
  docker_compose_language_service = 'docker-compose-language-service',
  gh_actions_ls = 'gh-actions-language-server',
  systemd_lsp = 'systemd-lsp',
  -- Other languages
  basedpyright = 'basedpyright',
  rust_analyzer = false, -- from rustup: `rustup component add rust-analyzer`
}
-- Non-LSP tools used by the servers above
local tools = {
  'shellcheck', -- diagnostics for bashls
  -- Formatters, see the Formatting section
  'prettier',
  'stylua',
  'shfmt',
  'ruff',
}

-- Install whatever is missing, in the background
local registry = require('mason-registry')
registry.refresh(function()
  local packages = vim.list_extend(vim.tbl_filter(function(p) return p end, vim.tbl_values(servers)), tools)
  for _, name in ipairs(packages) do
    local pkg = registry.get_package(name)
    if not pkg:is_installed() then pkg:install() end
  end
end)

-- Know the nvim API when editing this config
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
    },
  },
})
vim.lsp.config('jsonls', {
  settings = { json = { schemas = require('schemastore').json.schemas(), validate = { enable = true } } },
})
vim.lsp.config('yamlls', {
  settings = {
    yaml = {
      -- Disable the built-in schema store, SchemaStore.nvim provides the same catalog
      schemaStore = { enable = false, url = '' },
      schemas = require('schemastore').yaml.schemas(),
    },
  },
})

vim.lsp.enable(vim.tbl_keys(servers))

-- Show diagnostics at the end of the line, errors first, Nerd Font icons in the sign column
vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '\u{f057}',
      [vim.diagnostic.severity.WARN] = '\u{f071}',
      [vim.diagnostic.severity.INFO] = '\u{f05a}',
      [vim.diagnostic.severity.HINT] = '\u{f0eb}',
    },
  },
})

-- Rounded borders on floating windows (K documentation, diagnostics, signature help)
vim.o.winborder = 'rounded'

-- Keymaps on top of the native ones (K, grn, gra, grr, gri, grt, gO, [d, ]d...). Lists open in
-- the Snacks picker instead of the quickfix list, a single result jumps directly.
vim.keymap.set('n', 'gd', function() Snacks.picker.lsp_definitions() end, { desc = '[G]oto [D]efinition' })
vim.keymap.set('n', 'grr', function() Snacks.picker.lsp_references() end, { desc = 'LSP references' })
vim.keymap.set('n', 'gri', function() Snacks.picker.lsp_implementations() end, { desc = 'LSP implementations' })
vim.keymap.set('n', 'grt', function() Snacks.picker.lsp_type_definitions() end, { desc = 'LSP type definition' })
-- Every diagnostic, not only the ones of files under the working directory (the default)
vim.keymap.set('n', '<leader>sd', function() Snacks.picker.diagnostics({ filter = { cwd = false } }) end, { desc = '[S]earch [D]iagnostics' })
-- Full message of the diagnostics under the cursor, in a floating window
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show [D]iagnostic' })
-- Inlay hints: types and parameter names inferred by the server, shown inline. Off by default.
vim.keymap.set('n', '<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, { desc = '[T]oggle inlay [H]ints' })
