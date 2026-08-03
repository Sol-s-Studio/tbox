--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/colorSequenceKeypoint")

Helper.expectFail(
	Type:runtimeTypeCheck(Type.ColorSequenceKeypoint(), 123),
	"ColorSequenceKeypoint expected, but got number"
)
Helper.expectEqual(Type:luauBuild(Type.ColorSequenceKeypoint()), "ColorSequenceKeypoint")
Helper.expectEqual(Type:format(Type.ColorSequenceKeypoint()), "TColorSequenceKeypoint")

const schema = Type.ColorSequenceKeypoint({ minTime = 0.2, maxTime = 0.8 })

Helper.expectOk(Def.runtimeConstraintChecker(schema, { Time = 0.5 }))
Helper.expectFail(Def.runtimeConstraintChecker(schema, { Time = 0.9 }), "time too big. maximum allowed time is 0.8")
Helper.expectFail(Def.runtimeConstraintChecker(schema, { Time = 0.1 }), "time too small. minimum allowed time is 0.2")

return true
