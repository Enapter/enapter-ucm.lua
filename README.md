# Enapter UCM Stdlib

[![Busted](https://github.com/enapter/enapter-ucm.lua/actions/workflows/busted.yml/badge.svg)]()
[![Luacheck](https://github.com/enapter/enapter-ucm.lua/actions/workflows/luacheck.yml/badge.svg)]()
[![StyLua](https://github.com/enapter/enapter-ucm.lua/actions/workflows/stylua.yml/badge.svg)]()
[![Coverage Status](https://coveralls.io/repos/github/Enapter/enapter-ucm.lua/badge.svg?branch=main)](https://coveralls.io/github/Enapter/enapter-ucm.lua?branch=main)

This repository contains libraries for development and test Enapter UCMs.

## Config
`enapter.ucm.config` helps with ucm configurations. It [registers commands](https://developers.enapter.com/docs/reference/ucm/enapter#enapterregister_command_handler) to read and write UCM configuration into persistent storage.

### Example
Take for example an UCM with two configuration arguments:
- `api_url` — string with API URL. It has default vaule to public api host "api.units.com", but can be changed to use another server for testing or security purpose.
- `unit_id` — integer with connected unit ID. It should be set manually, because it is individual per UCM. So, it is required config option.

In `manifest.yml` (the following commands should be described)[https://developers.enapter.com/docs/reference#commands]:
```yml
commands:
  write_configuration:
    populate_values_command: read_configuration
    display_name: Configure
    group: config
    ui:
      icon: wrench-outline
    arguments:
      api_url:
        display_name: API URL
        type: integer
        default: api.units.com
      unit_id:
        display_name: Unit ID
        type: integer
        required: true
  read_configuration:
    display_name: Read Configuration
    group: config
    ui:
      icon: wrench-outline
```

And in Lua config should be initialised:
```lua
local API_URL_CONFIG = 'api_url'
local UNI_ID_CONFIG = 'unit_id'

config.init({
    [API_URL_CONFIG] = { type = 'string', default = 'api.units.com' },
    [UNI_ID_CONFIG] = { type = 'number', require = true }
})
```

After that commands to read/write config are registered and values can be get in Lua code via `config.read` and `config.read_all` methods.
