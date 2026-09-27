-- [[ Colorscheme ]]
vim.pack.add({ 'https://github.com/navarasu/onedark.nvim' })
require('onedark').setup({
  style = 'deep',
  -- Darker editor background (deep's own bg_d instead of #1a212e) for more contrast with the bars
  colors = { bg0 = '#141b24' },
})
require('onedark').load()
