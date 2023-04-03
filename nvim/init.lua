-- hello my name is viraat chandra and i love to program

require("session")
require("plugins")
require("settings")
require("colorscheme")

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    require("keymaps")
    require("commands")

    -- NOTE(vir): load local settings last
    require("lib/local_session").load_local_session()
  end
})

-- notes --
-- so $VIMRUNTIME/syntax/hitest.vim : see colors
--
-- project setup:
--  .clang-format       : clang-format config
--  .clang-tidy         : clang-tidy config
--  .flake8             : autopep8 config
--  pyrightconfig.json  : pyright config

-- ideas --
-- 1. toggle pin buffers (cannot delete pinned buffers)
-- 2. toggle buffers like primary terminal
-- 3. fix Q in new tab (same buffer)
-- 4. further work on terminal api
-- 5. fix doesnt to doesn't in config files

