# Give Codex and other terminal tools room for startup file-descriptor bursts.
if status is-interactive
    set -l current_limit (ulimit -Sn)
    if test "$current_limit" != unlimited; and test "$current_limit" -lt 4096
        ulimit -Sn 4096
    end
end
