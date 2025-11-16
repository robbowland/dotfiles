# -- (f)ile (e)xplorer
function fe --description "Use Yazi as a directory chooser and cd there" --wraps yazi
    set -l cwd_tmp (mktemp -t "yazi-cwd.XXXXXX")
    set -l pick_tmp (mktemp -t "yazi-choose.XXXXXX")

    if test -z "$cwd_tmp" -o -z "$pick_tmp"
        yazi $argv
        return
    end

    yazi --cwd-file "$cwd_tmp" --chooser-file "$pick_tmp" $argv

    set -l target ""
    if test -s "$pick_tmp"
        set target (string trim (head -n 1 "$pick_tmp"))
    end

    if test -n "$target"
        if test -d "$target"
            cd "$target"
        else if test -f "$target"
            nvim "$target"
        end
    end

    rm -f "$cwd_tmp" "$pick_tmp"
end
