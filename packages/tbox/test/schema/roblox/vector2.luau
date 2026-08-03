--!strict

const Type = require("../../../src")
const Helper = require("../../helper")
-- 제약 검사기는 Roblox 전역 없이 직접 확인해야 하므로 모듈을 바로 가져온다 (repo CLAUDE.md 참고)
const Def = require("../../../src/schema/roblox/vector2")

Helper.expectFail(Type:runtimeTypeCheck(Type.Vector2(), 123), "Vector2 expected, but got number")
Helper.expectEqual(Type:luauBuild(Type.Vector2()), "Vector2")
Helper.expectEqual(Type:format(Type.Vector2()), "TVector2")

-- Vector2 값의 프로퍼티 모양만 흉내낸 목(mock) 테이블
const function mockVector2(x: number, y: number)
	return { X = x, Y = y, Magnitude = math.sqrt(x * x + y * y) }
end

const schema = Type.Vector2({ maxMagnitude = 10, minMagnitude = 1 })

Helper.expectOk(Def.runtimeConstraintChecker(schema, mockVector2(3, 4)))
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockVector2(100, 0)),
	"Vector2 too long. maximum allowed magnitude is 10"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(schema, mockVector2(0.1, 0)),
	"Vector2 too short. minimum allowed magnitude is 1"
)

const strict = Type.Vector2({ integerOnly = true, notNan = true })
Helper.expectOk(Def.runtimeConstraintChecker(strict, mockVector2(1, 4)))
Helper.expectFail(
	Def.runtimeConstraintChecker(strict, mockVector2(1.5, 4)),
	"x component must be an integer, but got 1.5"
)
Helper.expectFail(Def.runtimeConstraintChecker(strict, mockVector2(0 / 0, 4)), "x component must not be nan")

const bounded = Type.Vector2({ min = mockVector2(0, 0) :: any, max = mockVector2(10, 10) :: any })
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockVector2(11, 0)),
	"x value too big. maximum allowed x value is 10"
)
Helper.expectFail(
	Def.runtimeConstraintChecker(bounded, mockVector2(-1, 0)),
	"x value too small. minimum allowed x value is 0"
)

return true
