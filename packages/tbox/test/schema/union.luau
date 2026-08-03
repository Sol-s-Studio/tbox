--!strict

const Type = require("../../src")
const Helper = require("../helper")

-- Optional 처럼 동작하는 hoisted union
const unionTest = Type.Union(Type.Tuple(Type.Number(), Type.Optional(Type.String())))
type unionTest = Type.Static<typeof(unionTest)> -- (number | string)?

Helper.expectOk(Type:runtimeTypeCheck(unionTest, 1))
Helper.expectOk(Type:runtimeTypeCheck(unionTest, "str"))
Helper.expectOk(Type:runtimeTypeCheck(unionTest, nil))
Helper.expectTrue(Type:canBeNil(unionTest), "a union containing an Optional branch should accept nil")

-- 오브젝트 유니온: 어떤 분기와도 일치하지 않으면 각 분기별 실패 사유를 모두 보여준다
const objectUnionTest = Type.Union(
	Type.Tuple(
		Type.Object({ a = Type.Boolean(), c = Type.Number() }),
		Type.Object({ b = Type.Boolean(), c = Type.Number() })
	)
)

Helper.expectFail(
	Type:runtimeTypeCheck(objectUnionTest, { c = 1 }),
	"union value check failed. value did not match any of the union members.\n"
		.. "  branch 1: required object property 'a' not exist.\n"
		.. "  branch 2: required object property 'b' not exist."
)
Helper.expectOk(Type:runtimeTypeCheck(objectUnionTest, { a = true, c = 1 }))

-- 제약 검사는 타입 검사를 먼저 통과하는 분기 하나에만 적용된다 (분기 선택엔 타입만 관여한다)
const constrainedUnion = Type.Union(Type.Tuple(Type.Number({ max = 10 }), Type.String()))
Helper.expectFail(Type:runtimeConstraintCheck(constrainedUnion, 11), "number too big. maximum allowed value is 10")

Helper.expectEqual(Type:luauBuild(unionTest), "(number) | ((string)?)")

return true
