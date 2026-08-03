--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/colorSequence")

Helper.expectFail(Type:runtimeTypeCheck(Type.ColorSequence(), 123), "ColorSequence expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.ColorSequence()), "ColorSequence")
Helper.expectEqual(Type:format(Type.ColorSequence()), "TColorSequence")

const function mockKeypoint(time: number)
	return { Time = time }
end

const schema = Type.ColorSequence({ minKeypoints = 2, maxKeypoints = 3 })
Helper.expectOk(Def.runtimeConstraintChecker(schema, { Keypoints = { mockKeypoint(0), mockKeypoint(1) } }))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, { Keypoints = { mockKeypoint(0) } }),
	"too few keypoints. minimum allowed keypoint count is 2"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(
		schema,
		{ Keypoints = { mockKeypoint(0), mockKeypoint(0.3), mockKeypoint(0.6), mockKeypoint(1) } }
	),
	"too many keypoints. maximum allowed keypoint count is 3"
)

-- strictKeypointOrder 는 엔진이 이미 강제하는 규칙이라 기본은 꺼져 있고, 켰을 때만 검사한다
const strict = Type.ColorSequence({ strictKeypointOrder = true })
Helper.expectOk(Def.runtimeConstraintChecker(strict, { Keypoints = { mockKeypoint(0), mockKeypoint(1) } }))
Helper.expectFail(
	Def.runtimeConstraintChecker(strict, { Keypoints = { mockKeypoint(0.1), mockKeypoint(1) } }),
	"first keypoint time must be 0"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(strict, { Keypoints = { mockKeypoint(0), mockKeypoint(0.9) } }),
	"last keypoint time must be 1"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(
		strict,
		{ Keypoints = { mockKeypoint(0), mockKeypoint(0.6), mockKeypoint(0.3), mockKeypoint(1) } }
	),
	"keypoint times must be in non-decreasing order, but keypoint 3 has a smaller time than keypoint 2"
)

return true
