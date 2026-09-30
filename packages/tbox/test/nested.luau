--!strict

-- 컨테이너 타입(Object/Merge/Array/Map/Union/Optional)을 여러 단계로 섞었을 때의 동작을 확인한다.
-- test/schema/* 는 각 타입을 1~2단계만 조합하므로, 여기서는 특히 다음을 본다.
--   * luauBuild/format 결과가 깊이와 관계없이 올바른 괄호 구조를 가지고, 실제로 파싱되는지
--   * 에러 메시지의 들여쓰기(Util.indent)가 단계마다 정확히 한 번씩 누적되는지
--   * nil 허용 여부(canBeNil)와 union 분기 선택이 중첩을 거쳐도 그대로 전달되는지

const Helper = require("./helper")
const Type = require("../src")

-- luauBuild 결과를 정확히 비교하고, 파싱되는지도 함께 확인한다
const function expectBuild(schema: any, expected: string)
    const built = Type:luauBuild(schema)
    if built ~= expected then
        error(`expected:\n  {expected}\nbut got:\n  {built}`, 2)
    end
    Helper.expectParsableType(built)
end

----------------------------------------------------------------------------------------------------
-- luauBuild / format
----------------------------------------------------------------------------------------------------

expectBuild(Type.Array(Type.Array(Type.Array(Type.Number()))), "{{{number}}}")
Helper.expectEqual(Type:format(Type.Array(Type.Array(Type.Number()))), "TArray<TArray<TNumber>>")

-- 모든 union 멤버와 optional 내부는 괄호로 감싸므로, 중첩돼도 우선순위가 섞이지 않는다
const unionOfUnions = Type.Union(
    Type.Tuple(
        Type.Union(Type.Tuple(Type.Number(), Type.String())),
        Type.Optional(Type.Union(Type.Tuple(Type.Boolean(), Type.Nil())))
    )
)
expectBuild(unionOfUnions, "((number) | (string)) | (((boolean) | (nil))?)")
Helper.expectEqual(Type:format(unionOfUnions), "TUnion<TUnion<TNumber, TString>, TOptional<TUnion<TBoolean, TNil>>>")

expectBuild(Type.Optional(Type.Optional(Type.Array(Type.Number()))), "(({number})?)?")

const mapOfObjects = Type.Map(
    Type.String(),
    Type.Object({
        list = Type.Array(Type.Optional(Type.Number())),
        nested = Type.Merge(Type.Tuple(Type.Object({ a = Type.Number() }), Type.Object({ b = Type.String() }))),
    })
)
expectBuild(mapOfObjects, "{ [string]: { list: {(number)?}, nested: { a: number, b: string } } }")
Helper.expectEqual(
    Type:format(mapOfObjects),
    "TMap<TString, TObject<{ list: TArray<TOptional<TNumber>>, nested: TMerge<TObject<{ a: TNumber }>, TObject<{ b: TString }>> }>>"
)

-- 식별자가 아닌 키와 이스케이프가 필요한 문자열 싱글톤이 깊은 곳에 있어도 올바르게 이스케이프된다
expectBuild(
    Type.Array(Type.Object({
        -- 싱글톤 타입으로 적을 수 없는 문자열이라 정적 검사를 우회한다
        ["with space"] = (Type.Singleton :: any)('say "hi"\0'),
        ["end"] = Type.Optional(Type.Array(Type.Map(Type.String(), Type.Boolean()))),
    })),
    '{{ ["end"]: ({{ [string]: boolean }})?, ["with space"]: "say \\"hi\\"\\000" }}'
)

-- 빈 Object 도 유효한 타입이다
expectBuild(Type.Array(Type.Object({})), "{{  }}")

----------------------------------------------------------------------------------------------------
-- 에러 메시지 들여쓰기 누적
----------------------------------------------------------------------------------------------------

-- 컨테이너마다 한 단계씩 들여쓰고, union 은 분기 메시지 전체를 한 단계 들여쓴다
const listOfUnion = Type.Object({
    list = Type.Array(Type.Union(Type.Tuple(Type.Number(), Type.Object({ x = Type.String() })))),
})
Helper.expectFail(
    Type:runtimeTypeCheck(listOfUnion, { list = { 1, { x = 5 } } }),
    table.concat({
        "object property 'list' type check failed.",
        "  array element type check failed at index 2.",
        "    union value check failed. value did not match any of the union members.",
        "      branch 1: number expected, but got table",
        "      branch 2: object property 'x' type check failed.",
        "        string expected, but got number",
    }, "\n")
)
Helper.expectOk(Type:runtimeTypeCheck(listOfUnion, { list = { 1, { x = "a" } } }))

-- union 안의 union: 안쪽 분기 목록이 바깥 분기 줄보다 한 단계 더 들여써진다
Helper.expectFail(
    Type:runtimeTypeCheck(unionOfUnions, {}),
    table.concat({
        "union value check failed. value did not match any of the union members.",
        "  branch 1: union value check failed. value did not match any of the union members.",
        "    branch 1: number expected, but got table",
        "    branch 2: string expected, but got table",
        "  branch 2: optional value is not nil, but its inner type check failed.",
        "    union value check failed. value did not match any of the union members.",
        "      branch 1: boolean expected, but got table",
        "      branch 2: nil expected, but got table",
    }, "\n")
)

-- 제약 검사도 같은 방식으로 누적된다
Helper.expectFail(
    Type:runtimeConstraintCheck(Type.Map(Type.String(), Type.Array(Type.Number({ max = 10 }))), { k = { 1, 50 } }),
    table.concat({
        "map value constraint check failed at index k.",
        "  array element constraint check failed at index 2.",
        "    number too big. maximum allowed value is 10",
    }, "\n")
)

-- 깊이를 늘려도 각 줄의 들여쓰기가 정확히 깊이 * 2 칸이다
const depth = 12
local deep: any = Type.Number()
for _ = 1, depth do
    deep = Type.Array(deep)
end
local deepValue: any = "leaf"
for _ = 1, depth do
    deepValue = { deepValue }
end
const deepCheck = Type:runtimeTypeCheck(deep, deepValue)
Helper.expectTrue(deepCheck ~= nil, "deeply nested wrong value should fail")
const lines = string.split((deepCheck :: () -> string)(), "\n")
Helper.expectEqual(#lines, depth + 1)
for index, line in lines do
    const indent = string.rep("  ", index - 1)
    const expected = if index <= depth
        then `{indent}array element type check failed at index 1.`
        else `{indent}number expected, but got string`
    Helper.expectEqual(line, expected)
end
Helper.expectEqual(Type:luauBuild(deep), `{string.rep("{", depth)}number{string.rep("}", depth)}`)

----------------------------------------------------------------------------------------------------
-- nil 허용 여부와 union 분기 선택
----------------------------------------------------------------------------------------------------

-- canBeNil 은 Union/Optional 을 거쳐 전달되어, 해당 Object 필드를 필수가 아니게 만든다
const nilableFields = Type.Object({
    viaNil = Type.Union(Type.Tuple(Type.Number(), Type.Nil())),
    viaOptional = Type.Union(Type.Tuple(Type.String(), Type.Optional(Type.Number()))),
    viaAny = Type.Any(),
    required = Type.Union(Type.Tuple(Type.Number(), Type.String())),
})
Helper.expectOk(Type:runtimeTypeCheck(nilableFields, { required = 1 }))
Helper.expectFail(Type:runtimeTypeCheck(nilableFields, {}), "required object property 'required' not exist.")

-- Merge 로 합쳐도 필드의 nil 허용 여부는 유지된다
const merged = Type.Merge(
    Type.Tuple(
        Type.Object({ a = Type.Optional(Type.Number()) }),
        Type.Merge(Type.Tuple(Type.Object({ b = Type.Number() })))
    )
)
Helper.expectOk(Type:runtimeTypeCheck(merged, { b = 1 }))
Helper.expectFail(Type:runtimeTypeCheck(merged, { a = 1 }), "required object property 'b' not exist.")

-- union 은 타입 검사만으로 분기를 고르고, 제약 검사는 고른 분기에만 한다.
-- 첫 분기의 타입 검사가 통과하면, 제약 검사에서 실패하더라도 뒤 분기로 넘어가지 않는다
-- (packages/tbox/CLAUDE.md "타입 검사와 제약 검사를 나눈 이유").
const unionOfArrays = Type.Union(Type.Tuple(Type.Array(Type.Number({ max = 10 })), Type.Array(Type.String())))
Helper.expectOk(Type:runtimeConstraintCheck(unionOfArrays, { "long string" }))
Helper.expectFail(
    Type:runtimeConstraintCheck(unionOfArrays, { 100 }),
    "array element constraint check failed at index 1.\n  number too big. maximum allowed value is 10"
)

-- Object 는 모르는 필드를 타입 검사에서 허용하고(확장 객체의 공변성) 제약 검사에서 거부한다.
-- 그래서 선택 필드만 가진 Object 가 union 앞쪽에 있으면, 뒤쪽 분기와 정확히 맞는 값도 앞 분기로
-- 선택된 뒤 제약 검사에서 실패한다. union 에 Object 를 넣을 때 순서를 조심해야 하는 이유다.
const shadowingUnion =
    Type.Union(Type.Tuple(Type.Object({ a = Type.Optional(Type.Number()) }), Type.Object({ b = Type.Number() })))
Helper.expectOk(Type:runtimeTypeCheck(shadowingUnion, { b = 1 }))
Helper.expectFail(Type:runtimeConstraintCheck(shadowingUnion, { b = 1 }), "object property 'b' is not allowed")

return true
