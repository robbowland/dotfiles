-- Keep dynamic search/filter context and selection counts, but omit the
-- redundant current-directory path from the persistent header.
function Header:cwd()
  local flags = self:flags()
  if flags == "" then
    return ""
  end

  return ui.Span(flags):style(th.mgr.cwd)
end
