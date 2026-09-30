--!strict

-- test/schema/roblox/cframe.luau 의 mock 시나리오를 실제 CFrame 값으로 다시 돌린다.
-- mock 은 FuzzyEq/Orthonormalize/Cross 결과를 흉내만 냈으므로, 여기서는 실제 생성 경로별로
-- 정규직교성/손잡이 검사가 기대대로 걸리는지(RobloxApi.md 의 CFrame 절 주장)를 확인한다.
const Type = require("../../../src")
const Helper = require("../../helper")
const Common = require("../common")

Helper.expectOk(Type:runtimeTypeCheck(Type.CFrame(), CFrame.new()))
Helper.expectOk(Type:runtimeTypeCheck(Type.CFrame(), CFrame.identity))
Helper.expectFail(Type:runtimeTypeCheck(Type.CFrame(), 123), "CFrame expected, but got number")
Helper.expectFail(Type:runtimeTypeCheck(Type.CFrame(), Vector3.new(1, 2, 3)), "CFrame expected, but got Vector3")

const schema = Type.CFrame({
    positionMin = Vector3.new(0, 0, 0),
    positionMax = Vector3.new(10, 10, 10),
    minPositionMagnitude = 1,
    maxPositionMagnitude = 20,
    notNan = true,
})

Helper.expectOk(Common.check(schema, CFrame.new(5, 5, 5)))
-- 회전이 섞여 있어도 위치 제약만 본다
Helper.expectOk(Common.check(schema, CFrame.new(5, 5, 5) * CFrame.Angles(0.3, 0.2, 0.1)))
-- 엔진은 nan 위치도 그대로 저장한다 (Studio 에서 확인)
Helper.expectFail(Common.check(schema, CFrame.new(0 / 0, 0, 0)), "nan is not allowed in cframe position")
Helper.expectFail(Common.check(schema, CFrame.new(20, 0, 0)), "position x value too big. maximum allowed x value is 10")
Helper.expectFail(
    Common.check(schema, CFrame.new(-1, 5, 5)),
    "position x value too small. minimum allowed x value is 0"
)
Helper.expectFail(
    Common.check(schema, CFrame.new(0.1, 0.1, 0.1)),
    "position too close to origin. minimum allowed magnitude is 1"
)

const farSchema = Type.CFrame({ maxPositionMagnitude = 20 })
Helper.expectFail(
    Common.check(farSchema, CFrame.new(30, 0, 0)),
    "position too far from origin. maximum allowed magnitude is 20"
)

-- 올바른 회전만 만드는 생성 경로는 orthonormalOnly / rightHandedOnly 를 모두 통과해야 한다
const orthonormalOnly = Type.CFrame({ orthonormalOnly = true })
const rightHandedOnly = Type.CFrame({ rightHandedOnly = true })
const validRotations = {
    CFrame.new(1, 2, 3),
    CFrame.Angles(0.3, 0.2, 0.1),
    CFrame.fromOrientation(1, 2, 3),
    CFrame.lookAt(Vector3.new(1, 2, 3), Vector3.new(-4, 5, 6)),
    CFrame.fromAxisAngle(Vector3.new(1, 1, 0).Unit, 0.7),
    CFrame.new(0, 0, 0, 0.5, 0.5, 0.5, 0.5),
    CFrame.fromMatrix(Vector3.zero, Vector3.xAxis, Vector3.yAxis),
    CFrame.Angles(0.3, 0.2, 0.1) * CFrame.Angles(1, 2, 3),
}
for _, cframe in validRotations do
    Helper.expectOk(Common.check(orthonormalOnly, cframe))
    Helper.expectOk(Common.check(rightHandedOnly, cframe))
end

-- 검증 없이 통과하는 12성분 생성자로 스케일이 섞인 회전을 만들면 orthonormalOnly 에 걸린다
const scaled = CFrame.new(0, 0, 0, 2, 0, 0, 0, 1, 0, 0, 0, 1)
Helper.expectFail(Common.check(orthonormalOnly, scaled), "cframe rotation must be orthonormal")

-- 누적 오차 수준의 드리프트는 기본 허용 오차(1e-5)로는 걸리고, orthonormalEpsilon 을 넓히면 통과한다
const drifted = CFrame.new(0, 0, 0, 1.001, 0, 0, 0, 1, 0, 0, 0, 1)
Helper.expectFail(Common.check(orthonormalOnly, drifted), "cframe rotation must be orthonormal")
Helper.expectOk(Common.check(Type.CFrame({ orthonormalOnly = true, orthonormalEpsilon = 1e-2 }), drifted))

-- 거울상(행렬식 -1)은 fromMatrix 4인자 / 12성분 생성자 두 경로 모두 엔진이 그대로 받아준다.
-- 정규직교이긴 하므로 orthonormalOnly 는 통과하고(두 옵션을 나눈 이유), rightHandedOnly 에서만 걸린다.
const mirroredByMatrix = CFrame.fromMatrix(Vector3.zero, Vector3.xAxis, Vector3.yAxis, -Vector3.zAxis)
const mirroredByComponents = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, -1)
const mirrorMessage = "cframe rotation must be right-handed. mirrored rotation is not allowed"
Helper.expectOk(Common.check(orthonormalOnly, mirroredByMatrix))
Helper.expectFail(Common.check(rightHandedOnly, mirroredByMatrix), mirrorMessage)
Helper.expectFail(Common.check(rightHandedOnly, mirroredByComponents), mirrorMessage)

-- Orthonormalize() 는 손잡이를 보존하므로 거울상을 고쳐주지 못한다 (RobloxApi.md 의 주장을 실제로 확인)
Helper.expectFail(Common.check(rightHandedOnly, mirroredByMatrix:Orthonormalize()), mirrorMessage)

return true
