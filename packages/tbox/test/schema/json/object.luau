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

-- 필드는 키를 정렬한 순서로 출력된다 (props 는 해시 테이블이라 순회 순서가 환경마다 달라질 수 있다)
Helper.expectEqual(Type:luauBuild(box), `\{ ["1aaa"]: number, hello: string, world: number }`)
Helper.expectEqual(Type:format(box), `TObject<\{ ["1aaa"]: TNumber, hello: TString, world: TNumber }>`)

-- NUL 이 들어간 프로퍼티 이름은 Luau 테이블 타입으로 표현할 수 없으므로 luauBuild 가 에러를 낸다.
-- (format 은 사람이 읽는 용도라 파싱될 필요가 없으므로 이스케이프해서 그대로 보여준다)
const nulKey = Type.Object({ ["a\0b"] = Type.Number() })
Helper.expectError(function()
    Type:luauBuild(nulKey)
end, "object property name 'a\\000b' contains a NUL character and cannot be expressed as a luau type")
Helper.expectError(function()
    Type:luauBuild(Type.Array(nulKey))
end, "object property name 'a\\000b' contains a NUL character and cannot be expressed as a luau type")
Helper.expectEqual(Type:format(nulKey), `TObject<\{ ["a\\000b"]: TNumber }>`)

-- 키가 많아도, 어떤 순서로 넣었어도 같은 문자열이 나온다
const manyKeys = {}
for _, key in { "zeta", "alpha", "mid", "b", "a", "Z", "_", "a1", "a_" } do
    manyKeys[key] = Type.Number()
end
Helper.expectEqual(
    Type:luauBuild(Type.Object(manyKeys)),
    "{ Z: number, _: number, a: number, a1: number, a_: number, alpha: number, b: number, mid: number, zeta: number }"
)

return true
