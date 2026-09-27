-- [[ Treesitter ]]
-- Parsers must match the nvim-treesitter version: update them whenever vim.pack updates the plugin.
-- Defined before vim.pack.add so it also catches updates done at startup.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(args)
    if args.data.spec.name == 'nvim-treesitter' and args.data.kind == 'update' then vim.schedule(function() vim.cmd('TSUpdate') end) end
  end,
})
vim.pack.add({
  'https://github.com/nvim-treesitter/nvim-treesitter',
  -- Keeps the signature of the current function/class at the top of the window
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
  -- Auto close and rename HTML/JSX tags
  'https://github.com/windwp/nvim-ts-autotag',
})

-- Parsers installed upfront, others are installed the first time a file of that language is opened
require('nvim-treesitter').install({
  'javascript',
  'typescript',
  'tsx',
  'jsdoc',
  'html',
  'css',
  'styled', -- CSS inside css`...` tagged templates (Lit, styled-components)
  'scss',
  'json',
  'yaml',
  'toml',
  'lua',
  'luadoc',
  'vim',
  'vimdoc',
  'query',
  'bash',
  'fish',
  'markdown',
  'markdown_inline',
  'python',
  'rust',
  'dockerfile',
  'gitcommit',
  'git_rebase',
  'gitignore',
  'diff',
  'regex',
})

-- Folds follow the syntax tree (zc/zo/za), everything is unfolded when opening a file, a closed
-- fold shows its first line with syntax highlighting
vim.o.foldlevelstart = 99
vim.o.foldtext = ''

local function treesitter_enable(buf, lang)
  if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, lang) then return end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win][0].foldmethod = 'expr'
    vim.wo[win][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  end
end

-- Parsers nvim-treesitter can install, listed on the first file without an installed parser
local available_parsers

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not lang then return end
    if vim.treesitter.language.add(lang) then
      treesitter_enable(args.buf, lang)
      return
    end
    available_parsers = available_parsers or require('nvim-treesitter').get_available()
    if vim.tbl_contains(available_parsers, lang) then
      require('nvim-treesitter').install(lang):await(function()
        vim.schedule(function() treesitter_enable(args.buf, lang) end)
      end)
    end
  end,
})

require('treesitter-context').setup({ max_lines = 5 })

-- Code text objects, used after an operator (d, c, y, v...): af / if a function with / without its
-- signature, ac / ic a class, aa / ia an argument. daf deletes the function under the cursor,
-- cia changes an argument. Lookahead: from outside, they target the next one on the line.
vim.pack.add({ { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' } })
require('nvim-treesitter-textobjects').setup({ select = { lookahead = true } })
for keys, capture in pairs({
  af = '@function.outer',
  ['if'] = '@function.inner',
  ac = '@class.outer',
  ic = '@class.inner',
  aa = '@parameter.outer',
  ia = '@parameter.inner',
}) do
  vim.keymap.set(
    { 'x', 'o' },
    keys,
    function() require('nvim-treesitter-textobjects.select').select_textobject(capture, 'textobjects') end,
    { desc = capture:sub(2) }
  )
end
require('nvim-ts-autotag').setup()
