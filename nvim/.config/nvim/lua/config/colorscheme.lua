-- [[ Colorscheme ]]
vim.pack.add({ 'https://github.com/navarasu/onedark.nvim' })
require('onedark').setup({
  style = 'deep',
  -- Darker editor background (deep's own bg_d instead of #1a212e) for more contrast with the bars
  colors = { bg0 = '#141b24' },
})
require('onedark').load()
-- Match highlighted in the picker preview (the symbol found): the Search background gets hidden by
-- the cursor line there, leaving dark text on dark. Colored text stays readable on any background.
vim.api.nvim_set_hl(0, 'SnacksPickerSearch', { fg = '#f2cc81', bold = true, underline = true })
