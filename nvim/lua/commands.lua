local misc = require('lib/misc')
local core = require('lib/core')
local colorscheme = require('colorscheme')
local utils = require('utils')
local plenary = require('plenary')

-- ui setup
vim.api.nvim_create_augroup('UISetup', {clear = true})
vim.api.nvim_create_autocmd('ColorScheme', {
    group = 'UISetup',
    pattern = '*',
    callback = colorscheme.ui_overrides,
})

-- defer to improve responsiveness
vim.defer_fn(function()
    vim.api.nvim_create_augroup('Misc', {clear = true})
    vim.api.nvim_create_autocmd('TextYankPost', { group = 'Misc', pattern = '*', callback = function() vim.highlight.on_yank({on_visual = true}) end })
    vim.api.nvim_create_autocmd('BufWritePre', { group = 'Misc', pattern = '*', callback = misc.strip_trailing_whitespaces })
    -- vim.api.nvim_create_autocmd('BufReadPost', { group = 'Misc', pattern = '*', command = 'silent! normal `"' })

    -- NOTE(vir): plugin ft remaps: vista, nvimtree
    vim.api.nvim_create_autocmd('FileType', {
        group = 'Misc',
        pattern = {'vista_kind', 'vista', 'NvimTree'},
        callback = function()
            utils.map('n', '<c-o>', '<cmd>wincmd p<cr>', { buffer = 0 })
        end,
    })

    -- terminal setup
    vim.api.nvim_create_augroup('TerminalSetup', {clear = true})
    vim.api.nvim_create_autocmd('TermOpen', {
        group = 'TerminalSetup',
        callback = function()
            vim.opt_local.filetype = 'terminal'
            vim.opt_local.number = false
            vim.opt_local.signcolumn = 'no'
        end
    })

    -- config reloading
    vim.api.nvim_create_augroup('Configs', {clear = true})
    vim.api.nvim_create_autocmd('BufWritePost', { group = 'Configs', pattern = '.nvimrc.lua', command = 'source <afile>' })
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = 'Configs',
        pattern = { core.get_homedir() .. '/.config/nvim/init.lua', core.get_homedir() .. '/.config/nvim/*/*.lua', },
        -- command = 'source $MYVIMRC',

        callback = function()
            local src_file = vim.fn.expand('<afile>')
            local rc_file = vim.fn.expand('$MYVIMRC')
            local rc_path = vim.fs.dirname(rc_file)
            local lua_path = plenary.Path.new(rc_path) .. '/lua/'

            local to_reload = core.foreach(
                vim.split(vim.fn.globpath(rc_path, '**/**.lua'), "\n"),
                function(_, full_path)
                    local path_obj = plenary.Path.new(full_path)
                    local rel_path = vim.fn.fnamemodify(path_obj:make_relative(lua_path), ':r')

                    -- NOTE(vir): skip files
                    --  1. not already loaded
                    --  2. lazy.nvim config cannot be reloaded
                    --  3. lazy.nvim plugin specs cannot be reloaded
                    if not core.table_contains(package.loaded, rel_path) then return end
                    if string.find(rel_path, 'plugins') then return end
                    if string.find(rel_path, 'plug-config/') then return end

                    -- unload mod
                    package.loaded[rel_path] = nil
                    return rel_path
                end
            )

            -- stop all servers before reloading
            vim.lsp.stop_client(vim.lsp.get_active_clients(), false)

            -- reload modules
            core.foreach(to_reload, function(_, mod) require(mod) end)

            -- NOTE(vir): special cases, only reload if modified
            if src_file == 'init.lua' then vim.cmd [[ source $MYVIMRC ]]  end
            utils.notify('[CONFIG] reloaded', 'info', {render='minimal'}, true)
        end
    })

    -- custom commands
    utils.add_command("Commands", function()
        local keys = core.apply(utils.workspace_config.commands, function(key, _) return key end)
        table.sort(keys, function(a, b) return a > b end)
        vim.ui.select(keys, { prompt = "Commands> " }, function(key) utils.workspace_config.commands[key]() end)
    end, {
        bang = false,
        nargs = 0,
        desc = "Custom Commands",
    })

    -- open repository in github (after selecting remote)
    if misc.get_git_root() ~= nil then
        utils.add_command('OpenInGithub', function(_)
            local remotes = misc.get_git_remotes()

            if #remotes > 1 then
                vim.ui.select(remotes, {prompt = 'remote> '}, function(remote)
                    misc.open_repo_on_github(remote)
                end)
            else
                misc.open_repo_on_github(remotes[1])
            end

        end, {
            bang = true,
            nargs = 0,
            desc = 'Open chosen remote on GitHub, in the Browser'
        }, true)
    end

    -- sudowrite to file
    utils.add_command('SudoWrite', function()
        vim.cmd [[
            write !sudo -A tee > /dev/null %
            edit
        ]]
    end, {bang = true, nargs = 0, desc = 'Sudo Write'}, true)

    -- messages in qflist
    utils.add_command('Messages', misc.show_messages, {
        bang = false,
        nargs = 0,
        desc = 'Show :messages in qflist',
    }, true)

    -- command output in qflist
    utils.add_command('Show', misc.show_command, {
        bang = false,
        nargs = '+',
        desc = 'Run Command and show output in qflist'
    })

    -- TODO(vir): do this in lua
    -- <cword> highlight toggle
    vim.cmd [[
        function! CWordHlToggle()
          let @/ = ''
          if exists('#auto_highlight')
            autocmd! auto_highlight
            augroup! auto_highlight
            setlocal updatetime=1000

            " echo 'highlight current word: off'
            lua require('utils').notify('<cword> highlight deactivated', 'debug', {render='minimal'}, true)

            return 0
          else
            augroup auto_highlight
              autocmd!
              autocmd CursorHold * let @/ = '\V\<'.escape(expand('<cword>'), '\').'\>'
            augroup end
            setl updatetime=250

            " echo 'highlight current word: on'
            lua require('utils').notify('<cword> highlight activated', 'info', {render='minimal'}, true)

            return 1
          endif
        endfunction
    ]]

    -- generate tags
    utils.add_command('[MISC] Generate Tags', function()
        require('plenary').Job:new({
            command = 'ctags',
            args = { '-R', '--excmd=combine', '--fields=+K' },
            cwd = vim.loop.cwd(),
            on_start = function() utils.notify('generating tags', 'debug', { render = 'minimal' }, true) end,
            on_exit = function() utils.notify('tags generated', 'info', { render = 'minimal' }, true) end
        }):start()
    end, nil, true)

    -- toggles
    utils.add_command('[UI] Toggle Context WinBar', misc.toggle_context_winbar, nil, true)
    utils.add_command('[UI] Toggle Thicc Seperators', misc.toggle_thicc_separators, nil, true)
    utils.add_command('[UI] Toggle Spellings', misc.toggle_spellings, nil, true)
    utils.add_command('[UI] Toggle Night Mode', misc.toggle_night_mode, nil, true)
    utils.add_command('[UI] Toggle CWord Highlights', 'if CWordHlToggle() | set hlsearch | endif', nil, true)
end, 0)

