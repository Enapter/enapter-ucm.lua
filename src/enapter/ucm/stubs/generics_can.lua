local builder = require('enapter.ucm.stubs.builder')

local function new_dummy_can()
  return {
    setup = function() end,
    get = function() return {} end,
  }
end
new_dummy_can = builder.wrap_new(new_dummy_can)

return {
  new_dummy_can = new_dummy_can,
  setup_generic_can = builder.setup_package('enapter.ucm.generics.can', new_dummy_can),
  teardown_generic_can = builder.teardown_package('enapter.ucm.generics.can'),
}
