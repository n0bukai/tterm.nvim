# TTerm
This is my own take on a toggleable terminal.
Persists and toggles a singular terminal buffer window.

Enables the configuration of commands which will be sent to that terminal on keypress,
even if the terminal buffer is not visible.
The command is dependent on the filetype of the buffers you have entered (BufEnter event).
Only the command matching the last visited filetype for which a command was defined will be used.

### Installation
With lazy:
```lua
require('lazy').setup({
  spec = {
        { "n0bukai/tterm.nvim",
            opts ={
                -- configuration here, details below
            },
        },
    },
}
```

### Configuration
On setup the following options can be configured (shown are the default values):
```lua
require("tterm").setup({
    location = "below", -- above|below|left|right|float, if not defines where the term window goes
    skip_keymaps = false, -- whether to skip default keymaps on setup
    command_on_show = false, -- whether to automatically send the command when showing the terminal
    show_on_command = true, -- whether to automatically show the terminal when sending a command
    clear_before_command = true -- whether to clear prior output on sending a command
    height = 15 -- if above or below window, how high it should be, else ignored
    width = 40 -- if left or right window, how wide it should be, else ignored
    x_offset = 200, -- if floating column offset, else ignored
    y_offset = 5, -- if floating line offset, else ignored
    commands = { -- a table of filetype, command pairs
        ["zig"] = "zig build",
        ["rust"] = "cargo build",
        ["c"] = "make",
        ["cpp"] = "make",
    }
})
```

The default keymaps mentioned in the options are:
```lua
vim.keymap.set("n", "<leader>tt", require("tterm").toggle_term,
    { desc = "[T]oggle [T]erminal" })

vim.keymap.set("n", "<leader>tc", require("tterm").execute_command,
    { desc = "[T]erminal [C]ommand" })
```

### Usage

The default keymaps are:
* \<leader\>tt to toggle the window
* \<leader\>tc to send a command
```lua
require("tterm").show_term() -- this may be used to ensure terminal window is shown
require("tterm").toggle_term() -- this is used by tt
require("tterm").execute_command() -- this is used by tc and ,depending on settings, after tt
``` 
                      
During the session one can add/remove command overrides:
```lua
require("tterm").add_command(filetype, command)
-- the following user command does the same thing, only the first argument is interpreted as filetype
-- :TermAddOverride {filetype} {Command}
-- for example :TermAddOverride lua echo 'Sending echo for lua'

require("tterm").remove_command(filetype)
-- the following user command does the same thing
-- :TermRemoveOverride {filetype}
```
The added overrides are lost with the session, for persistence use the setup() commands option.
