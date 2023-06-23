-- hello my name is viraat chandra and i love to program

-- NOTE(vir): do i need this?
vim.loader.enable()

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

-- ideas and todos --
-- 1. investigate effect of vim.loader.enable() on config reloading
-- 2. check generate tags command

