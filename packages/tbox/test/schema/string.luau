--!strict

const Type = require("../../src")
const Helper = require("../helper")

const schema = Type.String({ minLength = 2, maxLength = 5 })

Helper.expectOk(Type:runtimeTypeCheck(schema, "abc"))
Helper.expectFail(Type:runtimeTypeCheck(schema, 123), "string expected, but got number")

Helper.expectOk(Type:runtimeConstraintCheck(schema, "abc"))
Helper.expectFail(Type:runtimeConstraintCheck(schema, "a"), "string too short. minimum allowed length is 2 characters")
Helper.expectFail(
	Type:runtimeConstraintCheck(schema, "abcdef"),
	"string too long. maximum allowed length is 5 characters"
)

const utf8Only = Type.String({ vaildUtf8Only = true })
Helper.expectOk(Type:runtimeConstraintCheck(utf8Only, "hello"))
-- 0xFF 는 어떤 UTF-8 시퀀스로도 시작할 수 없는 바이트다
Helper.expectFail(Type:runtimeConstraintCheck(utf8Only, string.char(0xFF)), "invalid UTF-8 string")

Helper.expectEqual(Type:luauBuild(Type.String()), "string")
Helper.expectEqual(Type:format(Type.String()), "TString")

return true
