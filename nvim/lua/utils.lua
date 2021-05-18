local utils = {}

-- setup truncation limits
utils.truncation_limit_s = 80
utils.truncation_limit = 120
utils.truncation_limit_l = 160

-- setup keymaps
utils.map = function (mode, lhs, rhs, opts, buffer_nr)
    local options = { noremap = true }
    if opts then options = vim.tbl_extend('force', options, opts) end
    if buffer_nr then vim.api.nvim_buf_set_keymap(buffer_nr, mode, lhs, rhs, options)
    else vim.api.nvim_set_keymap(mode, lhs, rhs, options) end
end

-- randomize colorscheme
utils.RandomColors = function()
    vim.cmd [[
    colorscheme random
    colorscheme
    ]]
end

-- strip trailing whitespaces in file
utils.StripTrailingWhitespaces = function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_command('%s/\\s\\+$//e')
    vim.api.nvim_win_set_cursor(0, cursor)
end

-- diagnostics symbol config
utils.symbol_config = {
    indicator_seperator = '',
    indicator_info      = '[i]',
    indicator_hint      = '[@]',
    indicator_warning   = '[!]',
    indicator_error     = '[x]',

    sign_info      = 'i',
    sign_hint      = '@',
    sign_warning   = '!',
    sign_error     = 'x'
}

-- is buffer horizontally truncated
utils.is_htruncated = function(width)
  local current_width = vim.api.nvim_win_get_width(0)
  return current_width < width
end

-- is buffer verticall truncated
utils.is_vtruncated = function(height)
  local current_height = vim.api.nvim_win_get_height(0)
  return current_height < height
end

-- mode display name table
utils.modes = {
    ['n']  = 'Normal',
    ['no'] = 'N-Pending',
    ['v']  = 'Visual',
    ['V']  = 'V-Line',
    [''] = 'V-Block',
    ['s']  = 'Select',
    ['S']  = 'S-Line',
    [''] = 'S-Block',
    ['i']  = 'Insert',
    ['ic'] = 'Insert',
    ['R']  = 'Replace',
    ['Rv'] = 'V-Replace',
    ['c']  = 'Command',
    ['cv'] = 'Vim-Ex ',
    ['ce'] = 'Ex',
    ['r']  = 'Prompt',
    ['rm'] = 'More',
    ['r?'] = 'Confirm',
    ['!']  = 'Shell',
    ['t']  = 'Terminal'
}

return utils
