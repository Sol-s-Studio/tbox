--!strict

const Type = require("../../../src")
const Helper = require("../../helper")

const mergedObjectTest = Type.Merge(Type.Tuple(
	Type.Object({
		a = Type.Number({ notInf = true, notNan = true }),
	}),
	Type.Object({
		b = Type.Number({ max = 10 }),
	}),
	-- 중첩된 Merge 도 병합 대상이 될 수 있다
	Type.Merge(Type.Tuple(Type.Object({
		optional = Type.Optional(Type.Number()),
	})))
))

Helper.expectEqual(
	Type:format(mergedObjectTest),
	"TMerge<TObject<{ a: TNumber }>, TObject<{ b: TNumber }>, TMerge<TObject<{ optional: TOptional<TNumber> }>>>"
)
Helper.expectEqual(Type:luauBuild(mergedObjectTest), "{ a: number, optional: (number)?, b: number }")

Helper.expectFail(Type:runtimeTypeCheck(mergedObjectTest, {}), "required object property 'a' not exist.")
Helper.expectOk(Type:runtimeTypeCheck(mergedObjectTest, { a = 1, b = 2 }))

Helper.expectFail(
	Type:runtimeConstraintCheck(mergedObjectTest, { a = 1, b = 100 }),
	"object property 'b' constraint check failed.\n  number too big. maximum allowed value is 10"
)

-- Merge 는 Object 와 동일한 훅(runtimeTypeChecker/runtimeConstraintChecker/...)을 그대로 재사용한다
Helper.expectFail(
	Type:runtimeConstraintCheck(mergedObjectTest, { a = 1, b = 1, extra = true }),
	"object property 'extra' is not allowed"
)

const permissive = Type.Merge(Type.Tuple(Type.Object({ a = Type.Number() })), { allowUnknownProps = true })
Helper.expectOk(Type:runtimeConstraintCheck(permissive, { a = 1, extra = true }))

return true
