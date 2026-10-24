#!/bin/fish

######################################
# Kill every tmux server (default, -L
# and weaver sockets) and clear stale
# sockets.
######################################
function tmux-killall
    set -l tmpdir /tmp
    set -q TMUX_TMPDIR; and set tmpdir (string trim -r -c / -- $TMUX_TMPDIR)
    for sock in $tmpdir/tmux-(id -u)/*
        test -S $sock; or continue
        tmux -S $sock kill-server 2>/dev/null
        # Remove the socket only once nothing answers on it
        tmux -S $sock ls >/dev/null 2>&1; or rm -f $sock
    end
end
