local function new_dummy_can()
  return {
    setup = function() end,
    get = function() return {} end,
  }
end

local function setup_generic_can()
  local stub = { stubs = {} }
  package.loaded['enapter.ucm.generics.can'] = false
  package.preload['enapter.ucm.generics.can'] = function()
    return {
      new = function() return table.remove(stub.stubs, 1) or new_dummy_can() end,
    }
  end
  return stub
end

local function teardown_generic_can()
  package.loaded['enapter.ucm.generics.can'] = false
  package.preload['enapter.ucm.generics.can'] = nil
end

return {
  new_dummy_can = new_dummy_can,
  setup_generic_can = setup_generic_can,
  teardown_generic_can = teardown_generic_can,
}
