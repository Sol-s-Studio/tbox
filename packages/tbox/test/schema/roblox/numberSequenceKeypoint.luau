--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/numberSequenceKeypoint")

Helper.expectFail(
	Type:runtimeTypeCheck(Type.NumberSequenceKeypoint(), 123),
	"NumberSequenceKeypoint expected, but got number"
)
Helper.expectEqual(Type:luauBuild(Type.NumberSequenceKeypoint()), "NumberSequenceKeypoint")
Helper.expectEqual(Type:format(Type.NumberSequenceKeypoint()), "TNumberSequenceKeypoint")

const schema = Type.NumberSequenceKeypoint({
	minTime = 0.2,
	maxTime = 0.8,
	minValue = 0,
	maxValue = 1,
	maxEnvelope = 0.1,
})

Helper.expectOk(Def.runtimeConstraintChecker(schema, { Time = 0.5, Value = 0.5, Envelope = 0 }))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { Time = 0.9, Value = 0.5, Envelope = 0 }),
	"NumberSequenceKeypoint.Time too big. maximum allowed value is 0.8"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { Time = 0.1, Value = 0.5, Envelope = 0 }),
	"NumberSequenceKeypoint.Time too small. minimum allowed value is 0.2"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { Time = 0.5, Value = 2, Envelope = 0 }),
	"NumberSequenceKeypoint.Value too big. maximum allowed value is 1"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { Time = 0.5, Value = -1, Envelope = 0 }),
	"NumberSequenceKeypoint.Value too small. minimum allowed value is 0"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { Time = 0.5, Value = 0.5, Envelope = 0.5 }),
	"NumberSequenceKeypoint.Envelope too big. maximum allowed value is 0.1"
)

const zeroEnvelope = Type.NumberSequenceKeypoint({ envelopeMustBeZero = true })
Helper.expectOk(Def.runtimeConstraintChecker(zeroEnvelope, { Time = 0, Value = 0, Envelope = 0 }))
Helper.expectFail(
	Def.runtimeConstraintChecker(zeroEnvelope, { Time = 0, Value = 0, Envelope = 0.2 }),
	"NumberSequenceKeypoint.Envelope must be zero, but got 0.2"
)

return true
