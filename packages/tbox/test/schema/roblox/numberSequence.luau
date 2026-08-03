--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/numberSequence")

Helper.expectFail(Type:runtimeTypeCheck(Type.NumberSequence(), 123), "NumberSequence expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.NumberSequence()), "NumberSequence")
Helper.expectEqual(Type:format(Type.NumberSequence()), "TNumberSequence")

const function mockKeypoint(time: number, value: number, envelope: number?)
	return { Time = time, Value = value, Envelope = envelope or 0 }
end

const schema =
	Type.NumberSequence({ minKeypoints = 2, maxKeypoints = 3, minValue = 0, maxValue = 1, maxEnvelope = 0.2 })

Helper.expectOk(Def.runtimeConstraintChecker(schema, { Keypoints = { mockKeypoint(0, 0), mockKeypoint(1, 1) } }))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { Keypoints = { mockKeypoint(0, 0) } }),
	"NumberSequence has too few keypoints. minimum allowed count is 2"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, {
		Keypoints = { mockKeypoint(0, 0), mockKeypoint(0.3, 0), mockKeypoint(0.6, 0), mockKeypoint(1, 0) },
	}),
	"NumberSequence has too many keypoints. maximum allowed count is 3"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { Keypoints = { mockKeypoint(0, 0), mockKeypoint(1, 2) } }),
	"NumberSequence keypoint 2 Value too big. maximum allowed value is 1"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { Keypoints = { mockKeypoint(0, -1), mockKeypoint(1, 1) } }),
	"NumberSequence keypoint 1 Value too small. minimum allowed value is 0"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { Keypoints = { mockKeypoint(0, 0, 0.5), mockKeypoint(1, 1) } }),
	"NumberSequence keypoint 1 Envelope too big. maximum allowed value is 0.2"
)

const strict = Type.NumberSequence({ strictKeypointOrder = true })
Helper.expectFail(
	Def.runtimeConstraintChecker(strict, { Keypoints = { mockKeypoint(0, 0) } }),
	"NumberSequence must have at least 2 keypoints, but got 1"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(strict, { Keypoints = { mockKeypoint(0.1, 0), mockKeypoint(1, 1) } }),
	"NumberSequence first keypoint Time must be 0, but got 0.1"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(strict, { Keypoints = { mockKeypoint(0, 0), mockKeypoint(0.9, 1) } }),
	"NumberSequence last keypoint Time must be 1, but got 0.9"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(
		strict,
		{ Keypoints = { mockKeypoint(0, 0), mockKeypoint(0.6, 0), mockKeypoint(0.3, 0), mockKeypoint(1, 1) } }
	),
	"NumberSequence keypoints must have non-decreasing Time, but keypoint 3 has Time 0.3 which is less than keypoint 2's Time 0.6"
)

return true
