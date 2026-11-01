-- Rex's keys, as Ghostty's (~/.config/ghostty/config). Rex's look (font,
-- theme, chrome, Option as Alt) lives in its Settings, which this file
-- cannot set: settings.sh writes those. After a change: rex config reload.

local terminal = "com.superlogical.terminal"

-- Panes: ctrl+shift+h/j/k/l moves between them; cmd+d and cmd+shift+d
-- split right and down.
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+shift+" .. key, function()
    rex.session.focus_direction({ direction = direction })
    return true
  end)
end
rex.bind("cmd+d", "pane.split", { direction = "right" })
rex.bind("cmd+shift+d", "pane.split", { direction = "down" })

-- cmd+alt+d and cmd+alt+shift+d go to the program, as Ghostty sends them,
-- for weaver's tmux to split its panes (CSI 100;9~ and 100;10~). Not as
-- kitty-protocol keys: tmux would read those as alt+d. Outside tmux they do
-- nothing.
local function send(sequence)
  return function(ctx)
    if not ctx.block_id then
      return false
    end
    rex.block.call(terminal, "write", { block_id = ctx.block_id, data = sequence })
    return true
  end
end
rex.bind("cmd+alt+d", send("\27[100;9~"))
rex.bind("cmd+alt+shift+d", send("\27[100;10~"))

-- weaver's keys, in the Rex sessions weaver makes: weaver.lua, which wvr
-- writes as it starts on Rex (wvr --rex). None until it has.
pcall(require, "weaver")
