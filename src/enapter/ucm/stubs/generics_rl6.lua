local builder = require('enapter.ucm.stubs.builder')

local function new_dummy_rl6()
  return {
    setup = function() end,
    open = function() end,
    close = function() end,
    is_closed = function() return false end,
  }
end
new_dummy_rl6 = builder.wrap_new(new_dummy_rl6)

return {
  new_dummy_rl6 = new_dummy_rl6,
  setup_generic_rl6 = builder.setup_package('enapter.ucm.generics.rl6', new_dummy_rl6),
  teardown_generic_rl6 = builder.teardown_package('enapter.ucm.generics.rl6'),
}
