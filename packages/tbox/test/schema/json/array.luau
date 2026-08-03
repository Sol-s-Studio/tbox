--!strict

const Type = require("../../../src")
const Helper = require("../../helper")

const schema = Type.Array(Type.Boolean({ title = "metadata for document and type generation" }), { maxItems = 3 })

Helper.expectFail(Type:runtimeTypeCheck(schema, 123), "table expected for TArray<TBoolean>, but got number")
Helper.expectFail(
	Type:runtimeTypeCheck(schema, { true, false, 1 }),
	"array element type check failed at index 3.\n  boolean expected, but got number"
)
Helper.expectFail(Type:runtimeTypeCheck(schema, { [1] = true, x = false }), "arrays cannot have non-numeric keys")
Helper.expectOk(Type:runtimeTypeCheck(schema, { true, false, true }))

Helper.expectFail(
	Type:runtimeConstraintCheck(schema, { true, false, true, true }),
	"array too long. maximum allowed length is 3"
)

const fixed = Type.Array(Type.Number(), { fixedLength = 2 })
Helper.expectOk(Type:runtimeConstraintCheck(fixed, { 1, 2 }))
Helper.expectFail(Type:runtimeConstraintCheck(fixed, { 1, 2, 3 }), "allowed length is 2")

const minItems = Type.Array(Type.Number(), { minItems = 2 })
Helper.expectFail(Type:runtimeConstraintCheck(minItems, { 1 }), "array too short. minimum allowed length is 2")

const constrained = Type.Array(Type.Number({ max = 10 }))
Helper.expectFail(
	Type:runtimeConstraintCheck(constrained, { 1, 20 }),
	"array element constraint check failed at index 2.\n  number too big. maximum allowed value is 10"
)

Helper.expectEqual(Type:luauBuild(schema), "{boolean}")
Helper.expectEqual(Type:format(schema), "TArray<TBoolean>")

return true
