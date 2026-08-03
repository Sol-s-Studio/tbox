--!strict

const Type = require("../../src")
const Helper = require("../helper")

Helper.expectOk(Type:runtimeTypeCheck(Type.Any(), nil))
Helper.expectOk(Type:runtimeTypeCheck(Type.Any(), 123))
Helper.expectOk(Type:runtimeTypeCheck(Type.Any(), "hello"))
Helper.expectOk(Type:runtimeTypeCheck(Type.Any(), { 1, 2, 3 }))

-- Any 는 nil 도 허용하므로 Object 의 required 판정에서 optional 취급된다
Helper.expectTrue(Type:canBeNil(Type.Any()), "Any should accept nil")

Helper.expectEqual(Type:luauBuild(Type.Any()), "any")
Helper.expectEqual(Type:format(Type.Any()), "TAny")

return true
