local utils = require('utils')

utils.map('v', '<', '<gv')
utils.map('v', '>', '>gv')
utils.map('n', 'H', '^')
utils.map('n', 'L', '$')
utils.map('i', 'jj', '<esc>')
utils.map('n', 'U', '<c-r>')

utils.map('n', ';', ':')
utils.map('n', ':', ';')
utils.map('n', '<space>', 'za')

utils.map('n', '<c-w><c-l>', '<cmd>cclose<cr> <cmd>pclose<cr> <cmd>lclose<cr>')
utils.map('n', '<leader>2', '<c-w>o')
utils.map('n', '<leader>t', '<cmd>bn<cr>')
utils.map('n', '<leader>y', '<cmd>bN<cr>')
utils.map('n', '<leader>q', '<cmd>bd!<cr>')

utils.map('n', '<m-j>', '<cmd>resize +2<cr>')
utils.map('n', '<m-k>', '<cmd>resize -2<cr>')
utils.map('n', '<m-h>', '<cmd>vertical resize -2<cr>')
utils.map('n', '<m-l>', '<cmd>vertical resize +2<cr>')

utils.map('n', '<ScrollWheelUp>', '<c-Y>')
utils.map('n', '<ScrollWheelDown>', '<c-E>')

utils.map('t', '<esc>', '<c-\\><c-n>')
utils.map('t', '<c-h>', '<c-\\><c-w>h')
utils.map('t', '<c-j>', '<c-\\><c-w>j')
utils.map('t', '<c-k>', '<c-\\><c-w>k')
utils.map('t', '<c-l>', '<c-\\><c-w>l')

utils.map('n', '<up>', '<nop>')
utils.map('n', '<down>', '<nop>')
utils.map('n', '<left>', '<nop>')
utils.map('n', '<right>', '<nop>')
utils.map('i', '<up>', '<nop>')
utils.map('i', '<down>', '<nop>')
utils.map('i', '<left>', '<nop>')
utils.map('i', '<right>', '<nop>')

utils.map('n', '<leader>e', '<cmd>lua require("utils").RandomColors()<cr>')
utils.map('n', '<leader>3', '<cmd>if AutoHighlightToggle()<bar>set hlsearch<bar>endif<cr>')

vim.cmd [[
cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'W')?('w'):('W'))
cnoreabbrev <expr> Q ((getcmdtype() is# ':' && getcmdline() is# 'Q')?('q'):('Q'))
cnoreabbrev <expr> WQ ((getcmdtype() is# ':' && getcmdline() is# 'WQ')?('wq'):('WQ'))
cnoreabbrev <expr> Wq ((getcmdtype() is# ':' && getcmdline() is# 'Wq')?('wq'):('Wq'))
]]

utils.map('i', '<tab>', '<plug>(completion_smart_tab)', { noremap = false })
utils.map('i', '<s-tab>', '<plug>(completion_smart_s_tab)', { noremap = false })

vim.cmd [[
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
]]

if vim.fn.exists('fish') then
    vim.o.shell = 'fish'
    utils.map('n', '<leader>s', '<cmd>vsp term://fish<cr>')
elseif vim.fn.exists('zsh') then
    vim.o.shell = 'zsh'
    utils.map('n', '<leader>s', '<cmd>vsp term://zsh<cr>')
else
    vim.o.shell = 'bash'
    utils.map('n', '<leader>s', '<cmd>vsp term://bash<cr>')
end
