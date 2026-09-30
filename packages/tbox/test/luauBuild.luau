--!strict

-- 등록된 모든 스키마 타입의 luauBuild 결과가 실제 Luau 타입 문법으로 파싱되는지 확인한다.
-- 각 test/schema/* 는 기대 문자열만 비교하므로, 문자열이 틀린 모양이어도 기대값을 같이 틀리게 적으면
-- 통과해버린다. 여기서는 실제 파서에 직접 넣어 본다 (Helper.expectParsableType).
-- 새 스키마 타입을 추가하면 아래 samples 에도 추가해야 한다 — 빠뜨리면 마지막 커버리지 검사가 실패한다.

const Helper = require("./helper")
const Type = require("../src")

-- 아래 샘플들은 정적 타입이 아니라 런타임 출력만 본다. 싱글톤 타입으로 쓸 수 없는 문자열을 Singleton 에
-- 넘기거나, 타입이 섞인 샘플 목록을 다시 컨테이너에 넣는 것은 정적 검사를 일부러 우회해야 하므로
-- 타입이 없는 별칭을 쓴다.
const Untyped: any = Type

-- 타입마다 기본형과, 옵션에 따라 출력이 달라지는 경우를 모은다
const samples: { any } = {
    Type.Any(),
    Type.Boolean(),
    Type.Nil(),
    Type.Number(),
    Type.String(),
    Type.Vector(),
    Type.Unsafe(),
    Untyped.Unsafe({ luauType = "(number, string) -> ...boolean" }),
    Type.Singleton("plain" :: "plain"),
    Untyped.Singleton('"quoted"\n\0\\'),
    Type.Singleton(true :: true),
    Type.Singleton(false :: false),
    Type.Optional(Type.Number()),
    Type.Union(Type.Tuple(Type.Number())),
    Type.Union(Type.Tuple(Type.Number(), Type.String(), Type.Nil())),
    Type.Map(Type.String(), Type.Number()),
    Type.Object({}),
    Type.Object({ a = Type.Number(), ["b c"] = Type.String(), ["and"] = Type.Boolean(), ['"\\\n'] = Type.Nil() }),
    Type.Array(Type.Number()),
    Type.Merge(Type.Tuple(Type.Object({ a = Type.Number() }), Type.Object({ ["not ident"] = Type.String() }))),
    Type.Vector2(),
    Type.Vector3(),
    Type.CFrame(),
    Type.Color3(),
    Type.ColorSequence(),
    Type.ColorSequenceKeypoint(),
    Type.NumberRange(),
    Type.NumberSequence(),
    Type.NumberSequenceKeypoint(),
    Type.Rect(),
    Type.Region3(),
    Type.UDim(),
    Type.UDim2(),
    Type.DateTime(),
    Type.Instance("BasePart"),
    Type.Instance(nil),
    Type.Enum(),
    -- Roblox 전역이 없으므로 enumType 자리에 목 문자열을 넣는다 (test/schema/roblox/enumItem.luau 참고)
    Type.EnumItem("Material" :: any),
    Type.EnumItem(nil),
}

const covered: { [string]: true } = {}
for _, schema in samples do
    covered[schema.tag] = true
    Helper.expectParsableType(Type:luauBuild(schema))
    -- 어떤 스키마든 optional/array/union 안에 넣어도 파싱돼야 한다 (괄호 처리 확인)
    Helper.expectParsableType(Type:luauBuild(Untyped.Optional(schema)))
    Helper.expectParsableType(Type:luauBuild(Untyped.Array(schema)))
    Helper.expectParsableType(Type:luauBuild(Untyped.Union(Untyped.Tuple(schema, schema))))
    Helper.expectParsableType(Type:luauBuild(Untyped.Map(Type.String(), schema)))
    Helper.expectParsableType(Type:luauBuild(Untyped.Object({ field = schema })))
end

-- 기본 네임스페이스에 등록된 모든 타입이 위 samples 에 적어도 한 번 나와야 한다
for typeName in (Type :: any)._types do
    Helper.expectTrue(covered[typeName] == true, `test/luauBuild.luau has no sample for registered type '{typeName}'`)
end

return true
