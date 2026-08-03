--!strict

const Type = require("../../src")
const Helper = require("../helper")

const schema = Type.Optional(Type.Number({ min = 0 }))

Helper.expectOk(Type:runtimeTypeCheck(schema, nil))
Helper.expectOk(Type:runtimeTypeCheck(schema, 5))
Helper.expectFail(
	Type:runtimeTypeCheck(schema, "5"),
	"optional value is not nil, but its inner type check failed.\n  number expected, but got string"
)

Helper.expectTrue(Type:canBeNil(schema), "Optional should accept nil")

Helper.expectOk(Type:runtimeConstraintCheck(schema, nil))
Helper.expectOk(Type:runtimeConstraintCheck(schema, 5))
Helper.expectFail(Type:runtimeConstraintCheck(schema, -1), "number too small. minimum allowed value is 0")

Helper.expectEqual(Type:luauBuild(schema), "(number)?")
Helper.expectEqual(Type:format(schema), "TOptional<TNumber>")

return true
