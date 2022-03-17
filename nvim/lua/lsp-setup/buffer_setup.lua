local utils = require('utils')

-- setup general keymaps
local function setup_general_keymaps(_, buffer_nr)
    -- NOTE(vir): now using fzf-lua
    -- utils.map('n', '<leader>d', '<cmd>lua vim.lsp.buf.definition()<cr>', { silent = true }, buffer_nr)
    -- utils.map('n', '<leader>u', '<cmd>lua vim.lsp.buf.references()<cr>', { silent = true }, buffer_nr)
    -- utils.map('n', '<leader>U', '<cmd>lua vim.lsp.buf.document_symbols()<cr>', { silent = true }, buffer_nr)
    -- utils.map('n', '<a-cr>', '<cmd>lua vim.lsp.buf.code_action()<cr>', { silent = true }, buffer_nr)

    utils.map('n', '<leader>r', vim.lsp.buf.rename, {silent = true}, buffer_nr)
    utils.map('n', 'K', vim.lsp.buf.hover, {silent = true}, buffer_nr)

    utils.map('n', '[e', function() vim.diagnostic.goto_prev({ float = true }) end, {silent = true}, buffer_nr)
    utils.map('n', ']e', function() vim.diagnostic.goto_next({ float = true }) end, {silent = true}, buffer_nr)
    utils.map('n', '<leader>e', require("lsp-setup/utils").toggle_diagnostics_list, {silent = true}, buffer_nr)
end

-- setup independent keymaps
local function setup_independent_keymaps(client, buffer_nr)
    if client.resolved_capabilities.document_formatting then
        utils.map('n', '<c-f>', vim.lsp.buf.formatting, {silent = true}, buffer_nr)
    end

    if client.resolved_capabilities.document_range_formatting then
        utils.map('v', '<c-f>', vim.lsp.buf.range_formatting, {silent = true}, buffer_nr)
    end

    if client.name == 'clangd' then
        utils.map('n', '<f9>', '<cmd>ClangdSwitchSourceHeader<cr>', {}, buffer_nr)
    end
end

-- setup buffer options
local function setup_options(_, _)
    vim.opt_local.omnifunc = 'v:lua.vim.lsp.omnifunc'
    vim.opt_local.formatoptions = "cqnjlr"
end

-- setup buffer autocommands
local function setup_autocmds(client, buffer_nr)
    if client.resolved_capabilities.document_highlight then
        vim.api.nvim_create_augroup('LspHighlights', { clear = false })
        vim.api.nvim_create_autocmd('CursorHold', { group = 'LspHighlights', callback = vim.lsp.buf.document_highlight, buffer = buffer_nr })
        vim.api.nvim_create_autocmd('CursorMoved', { group = 'LspHighlights', callback = vim.lsp.buf.clear_references, buffer = buffer_nr })
    end

    if client.resolved_capabilities.document_symbol then
        vim.api.nvim_create_augroup('LspStates', { clear = false })
        vim.api.nvim_create_autocmd('CursorMoved,InsertLeave,BufEnter', { group = 'LspStates', callback = require('lsp-setup/utils').refresh_tag_state, buffer = buffer_nr })
        vim.api.nvim_create_autocmd('BufLeave', { group = 'LspStates', callback = require('lsp-setup/utils').reset_tag_state, buffer = buffer_nr })
    end

    vim.api.nvim_create_augroup('LspPopups', { clear = false })
    vim.api.nvim_create_autocmd('CursorHold', { group = 'LspPopups', callback = function() vim.diagnostic.open_float() end, buffer = buffer_nr })
end

-- setup highlights
local function setup_highlights()
  -- TODO(vir): convert to lua, figure out vim.highlight.clear
  vim.cmd [[
      highlight! link LspReferenceRead IncSearch
      highlight! link LspReferenceWrite IncSearch
      highlight! clear LspReferenceText
  ]]

  require('lsp-setup/utils').setup_lsp_icon_highlights()
end

return {
    setup_general_keymaps = setup_general_keymaps,
    setup_independent_keymaps = setup_independent_keymaps,
    setup_options = setup_options,
    setup_autocmds = setup_autocmds,
    setup_highlights = setup_highlights
}
