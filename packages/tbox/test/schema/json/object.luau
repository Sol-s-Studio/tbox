--!strict

const Type = require("../../../src")
const Helper = require("../../helper")

const box = Type.Object({
	hello = Type.String(),
	world = Type.Number(),
	["1aaa"] = Type.Number(),
})

Helper.expectFail(Type:runtimeTypeCheck(box, { hello = "", world = 1 }), "required object property '1aaa' not exist.")
Helper.expectFail(
	Type:runtimeTypeCheck(box, { hello = "", world = "" }),
	"object property 'world' type check failed.\n  number expected, but got string"
)
Helper.expectOk(Type:runtimeTypeCheck(box, { hello = "", world = 1, ["1aaa"] = 2 }))
Helper.expectFail(Type:runtimeTypeCheck(box, 123), `table expected for {Type:format(box)}, but got number`)
Helper.expectFail(Type:runtimeTypeCheck(box, { [1] = "x" }), "objects cannot have non-string keys")

-- 알 수 없는 프로퍼티는 타입 검사에서는 무시되고, 제약 검사에서 걸러진다
const withExtra = { hello = "", world = 1, ["1aaa"] = 2, extra = true }
Helper.expectOk(Type:runtimeTypeCheck(box, withExtra))
Helper.expectFail(Type:runtimeConstraintCheck(box, withExtra), "object property 'extra' is not allowed")

const permissive = Type.Object({ hello = Type.String() }, { allowUnknownProps = true })
Helper.expectOk(Type:runtimeConstraintCheck(permissive, { hello = "", extra = true }))

-- optional 프로퍼티는 없어도 required 위반이 아니다
const withOptional = Type.Object({ hello = Type.String(), maybe = Type.Optional(Type.Number()) })
Helper.expectOk(Type:runtimeTypeCheck(withOptional, { hello = "" }))

-- 확장된(더 많은 프로퍼티를 가진) 값도 타입 검사는 통과한다 - 공변 관계이므로 제약 검사에서 처리한다
const constraintCheckedBox = Type.Object({ hello = Type.String({ maxLength = 3 }) })
Helper.expectFail(
	Type:runtimeConstraintCheck(constraintCheckedBox, { hello = "toolong" }),
	"object property 'hello' constraint check failed.\n  string too long. maximum allowed length is 3 characters"
)

-- 정적 luau 타입으로도 추출된다
function useBox(body: Type.Static<typeof(box)>) end
useBox({
	["1aaa"] = 1,
	hello = "",
	world = 1,
})

Helper.expectEqual(Type:luauBuild(box), `\{ hello: string, ["1aaa"]: number, world: number }`)
Helper.expectEqual(Type:format(box), `TObject<\{ hello: TString, ["1aaa"]: TNumber, world: TNumber }>`)

return true
