local builder = require('enapter.ucm.stubs.builder')

local function new_dummy_di7()
  return {
    setup = function() end,
    is_closed = function() return false end,
  }
end

new_dummy_di7 = builder.wrap_new(new_dummy_di7)

return {
  new_dummy_di7 = new_dummy_di7,
  setup_generic_di7 = builder.setup_package('enapter.ucm.generics.di7', new_dummy_di7),
  teardown_generic_di7 = builder.teardown_package('enapter.ucm.generics.di7'),
}
