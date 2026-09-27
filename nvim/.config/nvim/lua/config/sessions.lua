-- [[ Sessions ]]
-- Per project, like an IDE: started without arguments in a folder, nvim reopens the files, splits
-- and tabs left there last time. The session is saved on exit, only when nvim was started without
-- arguments, so a quick `nvim file` does not overwrite it, and deleted when every file was
-- closed. Stored in the state directory, one file per working directory.
vim.o.sessionoptions = 'buffers,curdir,folds,tabpages,winsize'
local function session_file()
  local dir = vim.fn.stdpath('state') .. '/sessions/'
  vim.fn.mkdir(dir, 'p')
  return dir .. vim.fn.getcwd():gsub('/', '%%') .. '.vim'
end
vim.api.nvim_create_autocmd('VimEnter', {
  -- Nested so the restored buffers trigger their usual events (filetype, LSP, treesitter...)
  nested = true,
  callback = function()
    if vim.fn.argc() > 0 then return end
    local file = session_file()
    if vim.fn.filereadable(file) == 1 then vim.cmd('silent! source ' .. vim.fn.fnameescape(file)) end
  end,
})
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    if vim.fn.argc() > 0 then return end
    local has_files = vim.iter(vim.api.nvim_list_bufs()):any(function(buf) return vim.bo[buf].buflisted and vim.api.nvim_buf_get_name(buf) ~= '' end)
    -- Every file closed: forget the session, otherwise the previous one would come back
    if has_files then
      vim.cmd('mksession! ' .. vim.fn.fnameescape(session_file()))
    else
      vim.fn.delete(session_file())
    end
  end,
})
