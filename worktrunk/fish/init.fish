if command -q wt
    # Worktrunk's wrapper lets `wt switch` and `wt remove` change this shell's cwd.
    command wt config shell init fish | source
end
