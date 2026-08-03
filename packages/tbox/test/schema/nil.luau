--!strict

const Type = require("../../src")
const Helper = require("../helper")

Helper.expectOk(Type:runtimeTypeCheck(Type.Nil(), nil))
Helper.expectFail(Type:runtimeTypeCheck(Type.Nil(), 1), "nil expected, but got number")
Helper.expectTrue(Type:canBeNil(Type.Nil()), "Nil should accept nil")

Helper.expectEqual(Type:luauBuild(Type.Nil()), "nil")
Helper.expectEqual(Type:format(Type.Nil()), "TNil")

return true
