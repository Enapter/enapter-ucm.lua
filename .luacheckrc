-- https://luacheck.readthedocs.io/en/stable/warnings.html

-- Enapter Rule Engine API
local enapter_api = {
  enapter = {
    fields = {'log', 'device'}
  },
  storage = {
    fields = {
      'read', 'write', 'remove', 'err_to_str',
      'enable_error_mode', 'disable_error_mode',
    }
  },
  modbustcp = {
    fields = {
      'new'
    }
  }
}

stds.enapter = {
  read_globals = enapter_api
}

std = 'lua53+enapter'

ignore = {
  '212/self', -- allow unused `self`
  '411/ok', '411/error', '411/err', -- allow to re-define some variables
  '421/err', -- allow to shadow some variables
}
