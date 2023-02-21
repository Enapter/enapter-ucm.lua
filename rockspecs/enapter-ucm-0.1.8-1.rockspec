rockspec_format = "3.0"
package = "enapter-ucm"
local rock_version = "0.1.8"
local rock_release = "1"

version = ("%s-%s"):format(rock_version, rock_release)

source = {
  url = "git+https://github.com/Enapter/enapter-ucm.lua.git",
  branch = rock_version == "scm" and "master" or nil,
  tag = rock_version ~= "scm" and "v"..rock_version or nil,
}

description = {
  homepage = "http://developers.enapter.com",
  license = "MIT"
}

dependencies = {
  "lua ~> 5.3"
}

test_dependencies = {
  "busted",
  "luacov",
  "inspect"
}

build = {
  type = "builtin",
  modules = {
    ["enapter.ucm.config"] = "enapter/ucm/config.lua"
  }
}

test = {
  type = "busted"
}
