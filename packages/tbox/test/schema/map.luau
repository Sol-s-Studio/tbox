--!strict

const Type = require("../../src")
const Helper = require("../helper")

const schema = Type.Map(Type.String(), Type.Number(), { maxItems = 2, minItems = 1 })

Helper.expectOk(Type:runtimeTypeCheck(schema, { a = 1, b = 2 }))
Helper.expectFail(Type:runtimeTypeCheck(schema, 123), "table expected for TMap<TString, TNumber>, but got number")
Helper.expectFail(
	Type:runtimeTypeCheck(schema, { [1] = 1 }),
	"map key type check failed.\n  string expected, but got number"
)
Helper.expectFail(
	Type:runtimeTypeCheck(schema, { a = "not a number" }),
	"map value type check failed at index a.\n  number expected, but got string"
)

Helper.expectOk(Type:runtimeConstraintCheck(schema, { a = 1 }))
Helper.expectFail(Type:runtimeConstraintCheck(schema, {}), "map too small. minimum allowed length is 1")
Helper.expectFail(
	Type:runtimeConstraintCheck(schema, { a = 1, b = 2, c = 3 }),
	"map too big. maximum allowed length is 2"
)

Helper.expectEqual(Type:luauBuild(schema), "{ [string]: number }")
Helper.expectEqual(Type:format(schema), "TMap<TString, TNumber>")

return true
