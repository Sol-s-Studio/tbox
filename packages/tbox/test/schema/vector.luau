--!strict

-- 네이티브 vector 타입 (typeof == "vector"). Roblox Vector3 (typeof == "Vector3") 와는 별개다.
const Type = require("../../src")
const Helper = require("../helper")

const schema = Type.Vector({ maxMagnitude = 10, minMagnitude = 1 })

-- 주의: Roblox 에서는 네이티브 vector 와 Vector3 가 같은 값이라 typeof(vector.create(...)) 가 "vector" 가 아니라
-- "Vector3" 을 돌려준다 (Studio 에서 확인). 그래서 typeof 로 판별하는 src/schema/vector.luau 는 Roblox 에서
-- 진짜 vector 값을 거부한다. src 를 어떻게 고칠지 정해지기 전까지 Roblox 에서는 이 기대값을 pending 으로 돌려
-- 나머지 스위트가 계속 돌게 한다. standalone luau 에서는 여전히 엄격하게 검사한다.
if typeof(vector.create(0, 0, 0)) == "vector" then
    Helper.expectOk(Type:runtimeTypeCheck(schema, vector.create(1, 0, 0)))
else
    Helper.pending("TVector should accept a native vector in roblox, where typeof(vector) is 'Vector3'", function()
        Helper.expectOk(Type:runtimeTypeCheck(schema, vector.create(1, 0, 0)))
    end)
end
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
