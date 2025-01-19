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
                -- configuration here
            },
        },
    },
}
```

### Configuration
On setup the following options can be configured (shown are the default values):
```lua
require("tterm.nvim").setup({
    location = "below", -- above|below|left|right, defines where the term window goes
    skip_keymaps = false, -- whether to skip default keymaps on setup
    command_on_show = false, -- whether to automatically send the command when showing the terminal
    show_on_command = true, -- whether to automatically show the terminal when sending a command
    clear_before_command = true -- whether to clear prior output on sending a command
    height = 15 -- if above or below window, how high it should be, else ignored
    width = 40 -- if left or right window, how wide it should be, else ignored
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
vim.keymap.set("n", "<leader>tt", M.toggle_term,
    { desc = "[T]oggle [T]erminal" })

vim.keymap.set("n", "<leader>tc",
    function()
        if state.opts.show_on_command then
            print("Showing on command")
            require("tterm.nvim").show_term()
        end
        require("tterm.nvim").execute_command()
    end,
    { desc = "[T]erminal [C]ommand" })
```

### Usage

The default keymaps are:
* \<leader\>tt to toggle the window
* \<leader\>tc to send a command
```lua
require("tterm.nvim").show_term() -- this may be used after tc if show_on_command is true
require("tterm.nvim").toggle_term() -- this is used by tt
require("tterm.nvim").execute_command() -- this is used by tc and may be used after toggle if command_on_show is true
``` 
                      
During the session one can add/remove command overrides:
```lua
require("tterm.nvim").add_command(filetype, command)
-- the following user command does the same thing, only the first argument is interpreted as filetype
-- :TermAddOverride {filetype} {Command}
-- for example :TermAddOverride lua echo 'Sending echo for lua'

require("tterm.nvim").remove_command(filetype)
-- the following user command does the same thing
-- :TermRemoveOverride {filetype}
```
The added overrides are lost with the session, for persistence use the setup() commands option.
