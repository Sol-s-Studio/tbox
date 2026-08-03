--!strict

const Type = require("../../src")
const Helper = require("../helper")

Helper.expectOk(Type:runtimeTypeCheck(Type.Boolean(), true))
Helper.expectOk(Type:runtimeTypeCheck(Type.Boolean(), false))
Helper.expectFail(Type:runtimeTypeCheck(Type.Boolean(), 1), "boolean expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(Type.Boolean(), nil), "boolean expected, but got nil")

Helper.expectEqual(Type:luauBuild(Type.Boolean()), "boolean")
Helper.expectEqual(Type:format(Type.Boolean()), "TBoolean")

return true
