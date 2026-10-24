--- @sync entry
-- <Esc> cancels what yazi is doing, as by default: a find, visual mode, the
-- selection, a filter, a search. Inside Neovim (yazi.nvim sets YAZI_NVIM_ID),
-- where yazi is a popover, it closes yazi, like q, once nothing is left.
return {
  entry = function()
    local tab = cx.active
    local folder = tab.current
    local busy = tab.finder
      or tab.mode.is_visual
      or #tab.selected > 0
      or folder.files.filter
      or folder.cwd.is_search
    if busy or not os.getenv("YAZI_NVIM_ID") then
      ya.emit("escape", {})
    else
      ya.emit("quit", {})
    end
  end,
}
