--!strict

const Type = require("../../src")
const Helper = require("../helper")

const schema = Type.Singleton("hello" :: "hello")
Helper.expectOk(Type:runtimeTypeCheck(schema, "hello"))
Helper.expectFail(Type:runtimeTypeCheck(schema, "world"), `"hello" expected for Singleton<"hello">, but got string`)
Helper.expectFail(Type:runtimeTypeCheck(schema, nil), `"hello" expected for Singleton<"hello">, but got nil`)

Helper.expectEqual(Type:luauBuild(schema), `"hello"`)
Helper.expectEqual(Type:format(schema), `TSingleton<"hello">`)

const boolSchema = Type.Singleton(true :: true)
Helper.expectOk(Type:runtimeTypeCheck(boolSchema, true))
Helper.expectFail(Type:runtimeTypeCheck(boolSchema, false), "true expected for Singleton<true>, but got boolean")
Helper.expectEqual(Type:luauBuild(boolSchema), "true")

return true
