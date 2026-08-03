--!strict

-- 네이티브 vector 타입 (typeof == "vector"). Roblox Vector3 (typeof == "Vector3") 와는 별개다.
const Type = require("../../src")
const Helper = require("../helper")

const schema = Type.Vector({ maxMagnitude = 10, minMagnitude = 1 })

Helper.expectOk(Type:runtimeTypeCheck(schema, vector.create(1, 0, 0)))
Helper.expectFail(Type:runtimeTypeCheck(schema, 123), "vector expected, but got number")

Helper.expectOk(Type:runtimeConstraintCheck(schema, vector.create(1, 0, 0)))
Helper.expectFail(
	Type:runtimeConstraintCheck(schema, vector.create(100, 0, 0)),
	"vector too long. maximum allowed magnitude is 10"
)
Helper.expectFail(
	Type:runtimeConstraintCheck(schema, vector.create(0.1, 0, 0)),
	"vector too short. minimum allowed magnitude is 1"
)

const bounded = Type.Vector({ min = vector.create(0, 0, 0), max = vector.create(10, 10, 10) })
Helper.expectOk(Type:runtimeConstraintCheck(bounded, vector.create(5, 5, 5)))
Helper.expectFail(
	Type:runtimeConstraintCheck(bounded, vector.create(11, 0, 0)),
	"x value too big. maximum allowed x value is 10"
)
Helper.expectFail(
	Type:runtimeConstraintCheck(bounded, vector.create(-1, 0, 0)),
	"x value too small. minimum allowed x value is 0"
)

Helper.expectEqual(Type:luauBuild(Type.Vector()), "vector")
Helper.expectEqual(Type:format(Type.Vector()), "TVector")

return true
