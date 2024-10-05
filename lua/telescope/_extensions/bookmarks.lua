local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
   error "This plugins requires nvim-telescope/telescope.nvim"
end
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local entry_display = require "telescope.pickers.entry_display"
local conf = require("telescope.config").values
local config = require("bookmarks.config").config
local bm = require("bookmarks")
local utils = require "telescope.utils"
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local transform_mod = require('telescope.actions.mt').transform_mod

local function get_text(annotation)
   local pref = string.sub(annotation, 1, 2)
   local ret = config.keywords[pref]
   if ret == nil then
      ret = config.signs.ann.text .. " "
   end
   return ret .. annotation
end

local function get_list() 
    local allmarks = config.cache.data
    local marklist = {}
    for k, ma in pairs(allmarks) do
        for l, v in pairs(ma) do
            table.insert(marklist, {
                filename = k,
                lnum = tonumber(l),
                text = v.a and get_text(v.a) or v.m,
            })
        end
    end
    return marklist
end

local function display(entry)
    local displayer = entry_display.create {
        separator = "▏",
        items = {
            { width = 5 },
            { width = 100 },
            { remaining = true },
        },
    }
    local line_info = { entry.lnum, "TelescopeResultsLineNr" }
    return displayer {
        line_info,
        entry.text:gsub(".* | ", ""),
        utils.path_tail(entry.filename), -- or path_tail
    }
end

local function make_finder()
    return finders.new_table {
        results = get_list(),
        entry_maker = function(entry)
            return {
                valid = true,
                value = entry,
                display = display,
                ordinal = entry.filename .. entry.text,
                filename = entry.filename,
                lnum = entry.lnum,
                col = 1,
                text = entry.text,
            }
        end,
    }
end

function bm_delete(prompt_bufnr)
    local selectedEntry = action_state.get_selected_entry()
    bm.bookmark_del(selectedEntry.filename, selectedEntry.lnum)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(make_finder())
end

local bm_actions = transform_mod {
    delete_selected = bm_delete,
}

local function bookmark(opts)
    opts = opts or {}
    pickers.new(opts, {
        prompt_title = "bookmarks",
        finder = make_finder(),
        sorter = conf.generic_sorter(opts),
        previewer = conf.qflist_previewer(opts),
        attach_mappings = function(prompt_bufnr, map)
            map('n', '<del>', bm_actions.delete_selected)
            map('i', '<del>', bm_actions.delete_selected)
            return true
        end,
    }):find()
end

return telescope.register_extension { exports = { list = bookmark, actions = bm_actions } }
