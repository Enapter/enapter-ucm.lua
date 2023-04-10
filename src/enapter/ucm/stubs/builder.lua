return {
  wrap_new = function(dummy_constructor)
    return function()
      local dummy = dummy_constructor()
      dummy.should_return = function(self, fn_name, ...)
        local rets = { ... }
        self[fn_name] = function() return table.unpack(rets) end
      end
      return dummy
    end
  end,

  setup_package = function(name, dummy_constructor)
    return function()
      local stub = { stubs = {} }
      package.loaded[name] = false
      package.preload[name] = function()
        return {
          new = function() return table.remove(stub.stubs, 1) or dummy_constructor() end,
        }
      end
      return stub
    end
  end,

  teardown_package = function(name)
    return function()
      package.loaded[name] = false
      package.preload[name] = nil
    end
  end,
}
