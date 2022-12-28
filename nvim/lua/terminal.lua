local utils = require('utils')
local misc = require('lib/misc')

local run_config = utils.workspace_config.run_config
local truncation = utils.editor_config.truncation

-- toggle target_terminal
local function toggle_target(force_open)
    if run_config.target_terminal == nil then
        utils.notify('[terminal] target terminal not set', 'warn', { render = 'minimal' }, true)
        return
    end

    local target_winid = vim.fn.bufwinid(run_config.target_terminal.bufnr)

    if target_winid ~= -1 and #vim.api.nvim_list_wins() ~= 1 then
        if force_open then return end

        -- hide target
        if not pcall(vim.api.nvim_win_close, target_winid, false) then
            utils.notify('[terminal] target exited, resetting state', 'debug', { render = 'minimal' }, true)
            run_config.target_terminal = nil
        end
    else
        local split_dir = (utils.is_htruncated(truncation.truncation_limit_s_terminal) and "") or "v"

        -- open in split
        if not pcall(vim.cmd, split_dir .. 'split #' .. run_config.target_terminal.bufnr) then
            utils.notify('[terminal] target exited, resetting state', 'debug', { render = 'minimal' }, true)
            run_config.target_terminal = nil
        end
    end
end

-- send payload to target_terminal
local function send_to_target(payload, repeat_last)
    if run_config.target_terminal == nil then
        utils.notify('[terminal] target terminal not set', 'warn', { render = 'minimal' }, true)
        return
    end

    if vim.api.nvim_buf_is_loaded(run_config.target_terminal.bufnr) then
        -- not using pcalls intentionally, fails successfully
        if repeat_last then vim.cmd("call chansend(" .. run_config.target_terminal.job_id .. ', "\x1b\x5b\x41\\<cr>")')
        else vim.api.nvim_chan_send(run_config.target_terminal.job_id, payload .. "\n") end

        -- open target terminal and scroll to bottom
        toggle_target(true)
        misc.scroll_to_end(run_config.target_terminal.bufnr)
    else
        -- buf has been unloaded
        utils.notify('[terminal] target terminal does not exist, resetting state', 'debug', { render = 'minimal' }, true)
        run_config.target_terminal = nil
    end
end

-- set target_terminal/target_command
local function set_target(default)
    if vim.b.terminal_job_id ~= nil then
        -- default is not used within a temrinal buffer
        assert(not default)

        run_config.target_terminal = {
            bufnr = vim.api.nvim_get_current_buf(),
            job_id = vim.b.terminal_job_id,
        }

        utils.notify(
            string.format(
                "target_terminal set to: { job_id: %s, bufnr: %s }",
                run_config.target_terminal.job_id,
                run_config.target_terminal.bufnr
            ),
            "info",
            { render = "minimal" },
            true
        )
    else
        run_config.target_command = default or vim.fn.input('[terminal] target_command: ', '', 'shellcmd')
    end
end

-- run target_command
local function run_target_command()
    if run_config.target_command ~= "" then
        send_to_target(run_config.target_command, false)
    else
        utils.notify('[terminal] target command not set', 'warn', { render = 'minimal' }, true)
    end
end

-- run previous command in target_terminal
local function run_previous_command()
    send_to_target(nil, true)
end

-- send lines to target_terminal
local function run_selection(visual_mode)
    local payload = nil

    if visual_mode then
        -- take last visual selection
        local l1 = vim.api.nvim_buf_get_mark(0, "<")[1]
        local l2 = vim.api.nvim_buf_get_mark(0, ">")[1]
        if l1 > l2 then l1, l2 = l2, l1 end

        local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)
        payload = table.concat(lines, '\n')
    else
        -- take current line when called from normal mode
        -- it makes sense to trim this before feeding input
        local line = vim.api.nvim_win_get_cursor(0)[1]
        payload = vim.trim(vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1])
    end

    send_to_target(payload)
end

-- launch a terminal with the command in a split
local function launch_terminal(command, background, callback)
    local split_cmd = (utils.is_htruncated(truncation.truncation_limit_s_terminal) and "sp") or "vsp"
    vim.cmd(string.format('%s term://%s', split_cmd, vim.api.nvim_get_option_value('shell', {})))

    -- terminal state
    local term_state = {
        bufnr = vim.api.nvim_get_current_buf(),
        job_id = vim.b.terminal_job_id
    }

    -- this should not crash, so pcall not needed
    vim.api.nvim_chan_send(term_state.job_id, command .. "\n")
    utils.notify(command, 'info', { title = '[terminal] launched command' }, true)

    -- wrap up
    if callback then callback() end
    if background then vim.api.nvim_win_close(vim.fn.bufwinid(term_state.bufnr), true)
    else vim.cmd [[ wincmd p ]] end

    return term_state
end

return {
    -- run-config and setup
    toggle_target = toggle_target,
    send_to_target = send_to_target,
    set_target = set_target,

    run_target_command = run_target_command,
    run_previous_command = run_previous_command,
    run_selection = run_selection,

    -- general
    launch_terminal = launch_terminal,
}
