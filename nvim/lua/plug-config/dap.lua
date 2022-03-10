local dap = require('dap')
local dapui = require('dapui')
local utils = require('utils')
local core = require('lib/core')
local plenary = require('plenary')
local notify = require('notify')

dap.adapters.python = { type = 'executable', command = 'python3', args = {'-m', 'debugpy.adapter'} }
dap.adapters.codelldb = function(callback, _)
    plenary.Job:new({
        command = 'fish',
        args = {'--command', 'codelldb'},
        cwd = '~/',
        on_start = function() callback({type = 'server', host = '127.0.0.1', port = 13000}) end
    }):start()
end

dap.configurations.python = {
    {
        type = 'python',
        request = 'launch',
        program = '${file}',
        terminal = 'integrated',
        console = 'integratedTerminal',
        pythonPath = core.get_python()
    }
}

dap.configurations.c = {
    {
        type = "codelldb",
        request = "launch",
        cwd = '${workspaceFolder}',
        console = 'integratedTerminal',
        stopOnEntry = false,
        program = function() return vim.fn.input('executable: ', vim.fn.getcwd() .. '/', 'file') end
    }
}
dap.configurations.cpp = dap.configurations.c
dap.configurations.rust = dap.configurations.cpp

dap.repl.commands = vim.tbl_extend('force', dap.repl.commands, {
    exit = {'q', 'exit'},
    custom_commands = {
        ['.run_to_cursor'] = dap.run_to_cursor,
        ['.restart'] = dap.run_last
    }
})

dapui.setup({
    icons = {expanded = "-", collapsed = "$"},
    mappings = {
        expand = "<CR>",
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r"
    },
    sidebar = {
        elements = {
            {id = "scopes", size = 0.5},
            {id = "breakpoints", size = 0.25},
            {id = "stacks", size = 0.25}
        },
        size = 40,
        position = "right"
    },
    tray = {elements = {"repl", "watches"}, size = 10, position = "bottom"},
    floating = {border = "rounded", mappings = {close = "q"}}
})

local function setup_maps()
    utils.map('n', '<m-d>B', '<cmd>lua require("dap").set_breakpoint(vim.fn.input("breakpoint condition: "))<cr>', {}, 0)
    utils.map('n', '<m-d><m-1>', '<cmd>lua require("dap").step_over()<cr>', {}, 0)
    utils.map('n', '<m-d><m-2>', '<cmd>lua require("dap").step_into()<cr>', {}, 0)
    utils.map('n', '<m-d><m-3>', '<cmd>lua require("dap").step_out()<cr>', {}, 0)
    utils.map('n', '<m-d><m-q>', '<cmd>lua require("dap").close()<cr> ' ..
                   '<cmd>lua require("dap").repl.close()<cr>' ..
                   '<cmd>lua require("dapui").close()<cr>' ..
                   '<cmd>lua require("plug-config/dap").remove_maps()<cr>', {}, 0)

    utils.map('n', '<m-d>k', '<cmd>lua require("dapui").eval()<cr>', {}, 0)
    utils.map('n', '<f4>', '<cmd>lua require("dapui").toggle()<cr>', {}, 0)
end

local function remove_maps()
    utils.unmap('n', '<m-d>B', 0)
    utils.unmap('n', '<m-d><m-1>', 0)
    utils.unmap('n', '<m-d><m-2>', 0)
    utils.unmap('n', '<m-d><m-3>', 0)
    utils.unmap('n', '<m-d><m-q>', 0)
    utils.unmap('n', '<m-d>k', 0)
    utils.unmap('n', '<f4>', 0)
end

local function start_session()
    setup_maps()
    dapui.open()

    local info_string = string.format('[prog] %s', dap.session().config.program)
    notify(info_string, 'debug', {title = '[DAP] Session Started', timeout = 500})
end

local function terminate_session()
    remove_maps()
    dapui.close()
    dap.repl.close()

    local info_string = string.format('[prog] %s', dap.session().config.program)
    notify(info_string, 'debug', {title = '[DAP] Session Terminated', timeout = 500})
end

dap.listeners.after.event_initialized["dapui"] = start_session
dap.listeners.before.event_terminated["dapui"] = terminate_session
-- dap.listeners.before.event_exited["dapui"] = terminate_session

vim.fn.sign_define("DapStopped", {text = '=>', texthl = 'DiagnosticWarn'})
vim.fn.sign_define("DapBreakpoint", {text = '<>', texthl = 'DiagnosticInfo'})
vim.fn.sign_define("DapBreakpointRejected", {text = '!>', texthl = 'DiagnosticError'})
vim.fn.sign_define("DapBreakpointCondition", {text = '?>', texthl = 'DiagnosticInfo'})
vim.fn.sign_define("DapLogPoint", {text = '.>', texthl = 'DiagnosticInfo'})

utils.map('n', '<m-d>b', '<cmd>lua require("dap").toggle_breakpoint()<cr>', {}, 0)
utils.map('n', '<f5>', '<cmd>lua require("dap").continue()<cr>', {}, 0)

return {remove_maps = remove_maps, setup_maps = setup_maps}