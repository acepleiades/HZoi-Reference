local J=require("SceneZOI.Json")
local f=assert(io.open(TEST_CONTENT_ROOT.."/tests/fixtures/profiles.json","rb"));local p=J.decode(f:read("*a"));f:close()
require("SceneZOI.Profiles").set(p)
return p
