--!strict

-- 어떤 buffer-cursor 직렬화 라이브러리도 실제로 require 하지 않습니다. Cursor 는 완전히 불투명한
-- 제네릭 타입 파라미터입니다 - tbox_squish 는 Cursor 내부를 절대 들여다보지 않고 주입받은
-- push/pop 사이로 그대로 전달만 하므로, 구체적인 shape 를 알 필요가 자체가 없습니다.
--
-- 애초에 특정 라이브러리의 Cursor 구조체(`{ Buf: buffer, Pos: number }` 같은)를 그대로 베껴서
-- 타입으로 못박아두는 걸 시도했었는데, 조사해보니 그 구조 자체가 라이브러리/버전마다 다른
-- 안정적이지 않은 것이었습니다 - 업스트림 Data-Oriented-House/Squash 는 v4.0.0 에서 `{ Buf, Pos }`
-- 구조체를 `{ buffer }` 단일 원소 배열 + 위치를 buffer 첫 4바이트에 packing 하는 방식으로 바꿨고,
-- pesde 에 있는 두 포크(jiwonz/squash, anexpia/squish)조차 서로 또 다른 세 번째 shape 를 씁니다
-- (자세한 조사 내용은 CLAUDE.md 참고). 그래서 어떤 특정 버전/포크에도 구조적으로 종속되지 않도록
-- Cursor 를 제네릭으로 열어둡니다. tbox 본체가 Roblox 전역을 직접 참조하지 않는 것과 같은 철학입니다.

const Tbox = require("./roblox_packages/tbox")

-- 스키마 값 하나를 Cursor 에 넣고(push) 빼는(pop) 한 쌍의 함수입니다. Cursor 의 실제 타입은
-- 호출측이 쓰는 직렬화 라이브러리가 무엇이든 상관없이 그대로 통과시킵니다.
export type Codec<Cursor, Value> = {
    push: (cursor: Cursor, value: Value) -> (),
    pop: (cursor: Cursor) -> Value,
}

-- compile() 은 컨테이너 스키마(Object/Array/Map/Optional)를 직접 raw push/pop 나열로 풀어헤치지
-- 않고, 여기 있는 합성 빌더(record/array/map/optional)에 그대로 위임합니다. 이 조합을 어떻게
-- buffer 에 배치할지(필드 순서, 길이 인코딩 등)는 전적으로 주입받은 구현의 책임입니다 - squish 라면
-- `Squish.record`/`Squish.array`/`Squish.map`/`Squish.opt` 하나하나가 "여러 값을 묶어 한 번의
-- ser/des 호출로 왕복시키는" 합성 SerDes 를 이미 정확히 구현하고 있으므로, tbox_squish 는 그 내부
-- 배치 방식을 전혀 알 필요가 없습니다.
--
-- 유일한 예외는 Union 입니다. Union 의 분기는 값 자체를 보고(runtimeTypeCheck) 나서야 어떤 분기인지
-- 정해지는 동적 구조라서, record 처럼 고정된 필드 집합으로 미리 묶어둘 수 없습니다. 그래서 Union
-- 만은 이 파일이 직접 raw push 를 두 번(payload, 분기 번호) 호출합니다 - 그 순서를 결정하는 규약이
-- 아래에 있습니다. 이전에는 Object/Array/Map 도 raw push/pop 을 직접 나열해 이 규약에 맞춰 순서를
-- 손으로 뒤집었었는데, 그 방식은 주입받은 Cursor 가 실제로 이 규약을 따르는지 tbox_squish 가
-- 알아야만 하는 문제가 있었습니다(다른 라이브러리는 다른 규약을 쓸 수도 있음). 합성 빌더에 위임하면
-- 그 지식이 필요 없어지므로, Union 하나로 범위를 좁혔습니다.
--
-- (Union 에 필요한 규약: 같은 cursor 에 여러 값을 순서대로 push 했다면, pop 은 반드시 그 역순으로
-- 호출해야 원래 값을 정확히 돌려받습니다. anexpia/squish 로 직접 실험해 확인한 내용입니다 - squish
-- 의 Cursor 는 ser 할 때 위치를 버퍼 앞에서부터 늘리고 des 할 때는 버퍼 끝에서부터 줄이므로, 나중에
-- push(ser) 한 값이 가장 먼저 pop(des) 됩니다.)
export type Codecs<Cursor> = {
    number: Codec<Cursor, number>,
    string: Codec<Cursor, string>,
    boolean: Codec<Cursor, boolean>,
    -- union 분기 번호를 인코딩하는 데만 쓰는 음이 아닌 정수 codec 입니다. squish 라면 Squish.vlq()
    -- 정도가 적합합니다.
    uint: Codec<Cursor, number>,
    -- TNumber.format 이 지정된 스키마를 고정폭으로 압축하고 싶을 때만 채우면 됩니다. 비워두거나
    -- 해당 format 키가 없으면 항상 number codec 으로 대체됩니다.
    numberFormats: { [Tbox.TNumberFormat]: Codec<Cursor, number> }?,

    -- 이름 붙은 필드들을 하나의 값으로 묶습니다 (TObject/TMerge). squish 라면 Squish.record(fields).
    record: (fields: { [string]: Codec<Cursor, any> }) -> Codec<Cursor, { [string]: any }>,
    -- 동종 원소 배열입니다 (TArray). length 가 주어지면 고정 길이(정확히 그 개수만 인코딩하고 길이
    -- 자체는 쓰지 않음). squish 라면 Squish.array(elementSerDes, length).
    array: (elementCodec: Codec<Cursor, any>, length: number?) -> Codec<Cursor, { any }>,
    -- 동종 key-value map 입니다 (TMap). squish 라면 Squish.map(keySerDes, valueSerDes).
    map: (keyCodec: Codec<Cursor, any>, valueCodec: Codec<Cursor, any>) -> Codec<Cursor, { [any]: any }>,
    -- nil 을 허용하는 래퍼입니다 (TOptional). squish 라면 Squish.opt(innerSerDes).
    optional: (innerCodec: Codec<Cursor, any>) -> Codec<Cursor, any>,
}

-- compile() 이 재귀적으로 순회하는 스키마 인스턴스의 최소 형태입니다. tbox 는 스키마 인스턴스가
-- "tag + 타입별 필드로 이루어진 평범한 테이블"이라는 걸 공개 계약으로 문서화하고 있습니다
-- (packages/tbox/CLAUDE.md 참고). Base.TSchema 자체는 tbox 의 공개 API 가 아니라서 여기서
-- 필요한 만큼만 다시 선언합니다.
type AnySchema = { tag: string, [string]: any }

const function compileAny(schema: AnySchema, codecs: Codecs<any>): Codec<any, any>
    const tag = schema.tag

    if tag == "Number" then
        const format = schema.format :: Tbox.TNumberFormat?
        if format and codecs.numberFormats then
            const formatCodec = codecs.numberFormats[format]
            if formatCodec then
                return formatCodec
            end
        end
        return codecs.number
    elseif tag == "String" then
        return codecs.string
    elseif tag == "Boolean" then
        return codecs.boolean
    elseif tag == "Singleton" then
        -- 리터럴 값은 스키마 자체에 이미 고정되어 있으므로 buffer 에는 아무것도 쓰지 않습니다.
        const value = schema.value
        return {
            push = function(_cursor: any, _value: any): () end,
            pop = function(_cursor: any): any
                return value
            end,
        }
    elseif tag == "Optional" then
        return codecs.optional(compileAny(schema.inner, codecs))
    elseif tag == "Array" then
        const elementCodec = compileAny(schema.inner, codecs)
        return codecs.array(elementCodec, schema.fixedLength :: number?)
    elseif tag == "Object" or tag == "Merge" then
        const fieldCodecs = {} :: { [string]: Codec<any, any> }
        for key, propSchema in schema.props do
            fieldCodecs[key] = compileAny(propSchema, codecs)
        end
        return codecs.record(fieldCodecs)
    elseif tag == "Map" then
        return codecs.map(compileAny(schema.key, codecs), compileAny(schema.value, codecs))
    elseif tag == "Union" then
        -- 분기의 실제 shape 가 서로 다르고 값 자체를 봐야 어떤 분기인지 알 수 있는 동적 구조라서
        -- record 처럼 고정 필드로 묶을 수 없습니다. 그래서 여기만 예외적으로 raw push 를 두 번
        -- 호출합니다: tbox 의 TUnion 런타임 판별과 동일하게 첫 일치 분기를 고른 뒤, payload 를
        -- 먼저 push 하고 분기 번호를 마지막에 push 합니다 - 위 Codecs 타입 주석의 규약대로, 이래야
        -- pop 할 때 분기 번호가 가장 먼저 나옵니다.
        const n = schema.components.n
        const branchCodecs = table.create(n) :: { Codec<any, any> }
        for index = 1, n do
            branchCodecs[index] = compileAny(schema.components[index], codecs)
        end

        return {
            push = function(cursor: any, value: any): ()
                for index = 1, n do
                    const mismatch = Tbox:runtimeTypeCheck(schema.components[index], value)
                    if not mismatch then
                        branchCodecs[index].push(cursor, value)
                        codecs.uint.push(cursor, index)
                        return
                    end
                end
                error("tbox_squish: value did not match any union branch")
            end,
            pop = function(cursor: any): any
                const index = codecs.uint.pop(cursor)
                return branchCodecs[index].pop(cursor)
            end,
        }
    end

    error(
        `tbox_squish.compile: unsupported schema tag '{tag}'. Any/Nil/Unsafe/Vector/Roblox 데이터타입은 아직 지원하지 않습니다.`
    )
end

-- tbox 스키마 하나를 codecs 조합으로 컴파일해 그 스키마 전용 Codec 을 돌려줍니다. Number/String/
-- Boolean/Singleton/Optional/Array/Object/Merge/Union/Map 을 지원합니다. Any/Nil/Unsafe/Vector/
-- Roblox 데이터타입은 아직 지원하지 않고, compile 시점에 error 를 냅니다 (TODO).
const function compile<Schema, Cursor>(schema: Schema, codecs: Codecs<Cursor>): Codec<Cursor, Tbox.Static<Schema>>
    return (compileAny(schema :: any, codecs :: any) :: any) :: Codec<Cursor, Tbox.Static<Schema>>
end

return {
    compile = compile,
}
