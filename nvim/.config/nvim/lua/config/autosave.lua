-- [[ Autosave ]]
-- Like VS Code's "afterDelay": write the buffer 1s after the last change, in normal or insert mode.
local autosave_timers = {}
vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
  callback = function(args)
    local buf = args.buf
    local timer = autosave_timers[buf] or assert(vim.uv.new_timer())
    autosave_timers[buf] = timer
    timer:stop()
    timer:start(
      1000,
      0,
      vim.schedule_wrap(function()
        if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].modified then return end
        -- Only real files: no special buffers (help, terminal...), no unnamed or read-only ones
        if vim.bo[buf].buftype ~= '' or vim.bo[buf].readonly or vim.api.nvim_buf_get_name(buf) == '' then return end
        -- lockmarks keeps the '[ and '] marks of the last change intact
        vim.api.nvim_buf_call(buf, function() vim.cmd('silent! lockmarks update') end)
      end)
    )
  end,
})
vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
  callback = function(args)
    local timer = autosave_timers[args.buf]
    if timer then
      timer:close()
      autosave_timers[args.buf] = nil
    end
  end,
})
