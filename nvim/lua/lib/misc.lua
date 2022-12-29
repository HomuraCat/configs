local core = require("lib/core")
local utils = require("utils")

local ui_state = utils.editor_config.ui_state

-- strip filename from full path
local function strip_fname(path)
	return vim.fn.fnamemodify(path, ":t:r")
end

-- strip trailing whitespaces in file
local function strip_trailing_whitespaces()
	local cursor = vim.api.nvim_win_get_cursor(0)
	vim.api.nvim_command("%s/\\s\\+$//e")
	vim.api.nvim_win_set_cursor(0, cursor)
end

-- calculate indent spaces in string
local function calculate_indent(str, get)
    local s, e = string.find(str, '^%s*')
    local indent_size = e - s + 1
    if not get then return indent_size end
    return string.rep(' ', indent_size)
end

-- scroll buffer to end
local function scroll_to_end(bufnr)
    vim.api.nvim_buf_call(bufnr, function()
        vim.cmd [[ normal! G ]]
    end)
end

-- get git repo root dir (or nil)
local function get_git_root()
	local git_cmd = "git -C " .. vim.loop.cwd() .. " rev-parse --show-toplevel"
	local root, rc = core.lua_systemlist(git_cmd)

	if rc == 0 then
		return root[1]
	end
	return nil
end

-- get git remote names
local function get_git_remotes()
	local table, rc = core.lua_systemlist("git remote -v | cut -f 1 | uniq")
	if rc ~= 0 then
		return {}
	end

	return table
end

-- open repository on github
-- TODO(vir): make this universal (just works with github right now)
local function open_repo_on_github(remote)
	if get_git_root() == nil then
		utils.notify("not in a git repository", "error", { title = "could not open on github" }, true)
		return
    end

	remote = remote or "origin"

	local url, rc = core.lua_system("git config remote." .. remote .. ".url")
	if rc ~= 0 then
		utils.notify(
			string.format("found invalid remote url: [%s] -> %s", remote, url),
			"error", { title = "could not open on github" }, true
		)
		return
	end

    assert(url, 'could not get remote urls')
	url = url:gsub("git:", "https://")
	url = url:gsub("git@", "https://")
	url = url:gsub("com:", "com/")
	core.lua_system("open -u " .. url)

	utils.notify(string.format("[%s] -> %s", remote, url), "info", { title = "opening remote in browser" }, true)
end

-- window: toggle current window (maximum <-> original)
local function toggle_window()
	if vim.fn.winnr("$") > 1 then
		local original = vim.api.nvim_get_current_win()
		vim.cmd("tab sp")
		ui_state.window_state[vim.api.nvim_get_current_win()] = original
	else
		local maximized = vim.api.nvim_get_current_win()
		local original = ui_state.window_state[maximized]

		if original ~= nil then
			vim.cmd("tabclose")
			vim.api.nvim_set_current_win(original)
			ui_state.window_state[maximized] = nil
		end
	end
end

-- winbar: toggle context winbar in all windows
local function toggle_context_winbar()
    local callback = nil
    if ui_state.context_winbar then
        callback = function(_, bufnr)
            vim.api.nvim_buf_call(
                bufnr,
                function() vim.opt_local.winbar = nil end
            )
        end
    else
        callback = function(_, bufnr)
            vim.api.nvim_buf_call(
                bufnr,
                function() vim.opt_local.winbar = "%!luaeval(\"require('lsp-setup/lsp_utils').get_context_winbar(" .. bufnr .. ")\")" end
            )
        end
    end

    core.foreach(vim.api.nvim_list_bufs(), callback)
    ui_state.context_winbar = not ui_state.context_winbar
end

-- separator: toggle buffer separators (thick <-> default)
local function toggle_thicc_separators()
	if ui_state.thick_separators == true then
		vim.opt.fillchars = {
			horiz = nil,
			horizup = nil,
			horizdown = nil,
			vert = nil,
			vertleft = nil,
			vertright = nil,
			verthoriz = nil,
		}

        ui_state.thick_separators = false
		utils.notify("thiccness dectivated", "debug", { render = "minimal" })
	else
		vim.opt.fillchars = {
			horiz = "━",
			horizup = "┻",
			horizdown = "┳",
			vert = "┃",
			vertleft = "┫",
			vertright = "┣",
			verthoriz = "╋",
		}

        ui_state.thick_separators = true
		utils.notify("thiccness activated", "info", { render = "minimal" })
	end
end

-- spellings: toggle spellings globally
local function toggle_spellings()
	if vim.api.nvim_get_option_value("spell", { scope = "global" }) then
		vim.opt.spell = false
		utils.notify("spellings deactivated", "debug", { render = "minimal" }, true)
	else
		vim.opt.spell = true
		utils.notify("spellings activated", "info", { render = "minimal" }, true)
	end
end

-- laststatus: toggle between global and local statusline
local function toggle_global_statusline(force_local)
	if vim.api.nvim_get_option_value("laststatus", { scope = "global" }) == 3 or force_local then
		vim.opt.laststatus = 2
		utils.notify("global statusline deactivated", "debug", { render = "minimal" })
	else
		vim.opt.laststatus = 3
		utils.notify("global statusline activated", "debug", { render = "minimal" })
	end
end

-- toggle between dark/light mode
local function toggle_night_mode()
    if vim.api.nvim_get_option_value('background', { scope = 'global' }) == 'dark' then
        vim.api.nvim_set_option_value('background', 'light', { scope = 'global' })
    else
        vim.api.nvim_set_option_value('background', 'dark', { scope = 'global' })
    end
end

-- quickfix: toggle qflist
local function toggle_qflist()
    if vim.tbl_isempty(core.filter(vim.fn.getwininfo(), function(_, win) return win.quickfix == 1 end)) then
		vim.cmd [[ belowright copen ]]
	else
		vim.cmd [[ cclose ]]
	end
end

-- send :messages to qflist
local function show_messages()
	local messages = vim.api.nvim_exec("messages", true)
	local entries = {}

	for _, line in ipairs(vim.split(messages, "\n", true)) do
		table.insert(entries, { text = line })
	end

    utils.qf_populate(entries, "r", "Messages", true)
end

-- send :command output to qflist
local function show_command(command)
	command = command.args

	local output = vim.api.nvim_exec(command, true)
	local entries = {}

	for _, line in ipairs(vim.split(output, "\n", true)) do
		table.insert(entries, { text = line })
	end

    utils.qf_populate(entries, "r", "Command Output")
end

-- randomize colorscheme
local function random_colors()
    local mode = vim.api.nvim_get_option_value('background', { scope = 'local' })
    local choices = require('colorscheme').preferred[mode]

    local target = choices[math.random(1, #choices)]

    if type(target) == 'function' then
        target()
    else
        vim.cmd.colorscheme(target)
    end
end

return {
    -- utils
	strip_fname = strip_fname,
	strip_trailing_whitespaces = strip_trailing_whitespaces,
    calculate_indent = calculate_indent,
    scroll_to_end = scroll_to_end,

    -- repo related
	get_git_root = get_git_root,
	get_git_remotes = get_git_remotes,
	open_repo_on_github = open_repo_on_github,

    -- toggles
	toggle_window = toggle_window,
    toggle_context_winbar = toggle_context_winbar,
	toggle_thicc_separators = toggle_thicc_separators,
	toggle_spellings = toggle_spellings,
	toggle_global_statusline = toggle_global_statusline,
    toggle_night_mode = toggle_night_mode,
	toggle_qflist = toggle_qflist,

    -- misc
	show_messages = show_messages,
	show_command = show_command,
    random_colors = random_colors,
}
