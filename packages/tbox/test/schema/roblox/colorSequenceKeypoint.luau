--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
const Def = require("../../../src/schema/roblox/colorSequenceKeypoint")
const Util = require("../../../src/util")

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

-- 실제 Time 은 float32 로 저장된다 (ColorSequenceKeypoint.new(0.8).Time == 0.800000011920929). 경계값 그 자체로
-- 만든 키포인트는 경계를 float32 로 맞춰 비교하므로 통과해야 한다
Helper.expectOk(Def.runtimeConstraintChecker(schema, { Time = Util.toFloat32(0.8) }))
Helper.expectOk(Def.runtimeConstraintChecker(schema, { Time = Util.toFloat32(0.2) }))

return true
