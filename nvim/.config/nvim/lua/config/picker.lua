-- [[ Picker ]]
-- Snacks picker (set up in snacks.lua): fuzzy search for files, grep, symbols, buffers...
-- Relies on the fd and rg binaries.
local picker = Snacks.picker

-- The "project" searched by the picker is the git root of the current file, like the tabline,
-- falling back to the working directory outside a repo.
local function project_root() return vim.fs.root(0, '.git') or vim.fn.getcwd() end

-- Classes and interfaces only. The kind filter is per filetype, with a fallback on `default`:
-- the filetypes snacks configures itself are overridden too.
local class_kinds = { 'Class', 'Interface' }
local class_filter = { default = class_kinds, lua = class_kinds, markdown = class_kinds, help = class_kinds }

local function map_search(keys, desc, fn) vim.keymap.set('n', keys, fn, { desc = desc }) end
map_search('<leader><leader>', 'Search files', function() picker.files({ cwd = project_root(), hidden = true }) end)
map_search('<leader>sf', '[S]earch [F]iles', function() picker.files({ cwd = project_root(), hidden = true }) end)
map_search('<leader>sg', '[S]earch by [G]rep', function() picker.grep({ cwd = project_root(), hidden = true }) end)
map_search('<leader>ss', '[S]earch [S]ymbols in file', function() picker.lsp_symbols() end)
map_search('<leader>sS', '[S]earch [S]ymbols in project', function() picker.lsp_workspace_symbols() end)
map_search('<leader>sc', '[S]earch [C]lasses', function() picker.lsp_workspace_symbols({ filter = class_filter }) end)
map_search('<leader>sa', '[S]earch [A]ctions (commands)', function() picker.commands() end)
map_search('<leader>sb', '[S]earch [B]uffers', function() picker.buffers() end)
map_search('<leader>sr', '[S]earch [R]esume', function() picker.resume() end)
map_search('<leader>s.', '[S]earch recent files', function() picker.recent() end)
map_search('<leader>sh', '[S]earch [H]elp', function() picker.help() end)
map_search('<leader>sk', '[S]earch [K]eymaps', function() picker.keymaps() end)
