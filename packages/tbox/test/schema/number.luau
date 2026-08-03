--!strict

const Type = require("../../src")
const Helper = require("../helper")

const schema = Type.Number({ min = 0, max = 10 })
Helper.expectOk(Type:runtimeTypeCheck(schema, 5))
Helper.expectFail(Type:runtimeTypeCheck(schema, "5"), "number expected, but got string")

Helper.expectOk(Type:runtimeConstraintCheck(schema, 5))
Helper.expectFail(Type:runtimeConstraintCheck(schema, 11), "number too big. maximum allowed value is 10")
Helper.expectFail(Type:runtimeConstraintCheck(schema, -1), "number too small. minimum allowed value is 0")

const notInf = Type.Number({ notInf = true })
Helper.expectOk(Type:runtimeConstraintCheck(notInf, 1))
Helper.expectFail(Type:runtimeConstraintCheck(notInf, math.huge), "inf is not allowed")

const notNan = Type.Number({ notNan = true })
Helper.expectFail(Type:runtimeConstraintCheck(notNan, 0 / 0), "nan is not allowed")

const isFinite = Type.Number({ isFinite = true })
Helper.expectOk(Type:runtimeConstraintCheck(isFinite, 1))
Helper.expectFail(
	Type:runtimeConstraintCheck(isFinite, math.huge),
	"value must be a finite number, but a non-finite value inf was provided"
)

const notFinite = Type.Number({ isFinite = false })
Helper.expectOk(Type:runtimeConstraintCheck(notFinite, math.huge))
Helper.expectFail(
	Type:runtimeConstraintCheck(notFinite, 1),
	"value must be a non-finite number, but a finite value 1 was provided"
)

const multipleOf = Type.Number({ multipleOf = 5 })
Helper.expectOk(Type:runtimeConstraintCheck(multipleOf, 10))
Helper.expectFail(Type:runtimeConstraintCheck(multipleOf, 7), "value must be multiple of 5 with offset 0, but got 7")

const multipleOfOffset = Type.Number({ multipleOf = 5, multipleOfOffset = 2 })
Helper.expectOk(Type:runtimeConstraintCheck(multipleOfOffset, 7))
Helper.expectFail(
	Type:runtimeConstraintCheck(multipleOfOffset, 10),
	"value must be multiple of 5 with offset 2, but got 10"
)

Helper.expectEqual(Type:luauBuild(Type.Number()), "number")
Helper.expectEqual(Type:format(Type.Number()), "TNumber")

return true
