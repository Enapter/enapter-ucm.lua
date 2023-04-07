local t = {}

for _, pkg in ipairs({
  'enapter.ucm.stubs.enapter_ucm',
  'enapter.ucm.stubs.generics_rl6',
}) do
  for k, v in pairs(require(pkg)) do
    t[k] = v
  end
end

return t
