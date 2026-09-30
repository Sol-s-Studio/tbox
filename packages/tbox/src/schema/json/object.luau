--!strict

const Base = require("../../base")
const Types = require("../../types")
const Util = require("../../util")
const defaultUntypedNamespace = require("../../registry").defaultUntypedNamespace

export type TObjectProps = { props: { [string]: Base.TSchema }, allowUnknownProps: boolean? }
export type TObject<Props> =
    TObjectProps
    & Base.TSchema
    & Types.InnerType<Types.TObjectPropsFlatten<Props>>
    & Types.NamedType<"Object">
export type TObjectOptions = Types.Merge<{
    allowUnknownProps: boolean?,
}, Base.TSchemaOptions>

const function Object<Props>(props: { [string]: Base.TSchema } & Props, options: TObjectOptions?): TObject<Props>
    options = options or ({} :: TObjectOptions)
    return Base.SchemaFactory<<TObject<Props>>>("Object", options, {
        props = props,
        allowUnknownProps = options.allowUnknownProps,
    })
end

-- props 의 키를 정렬해서 돌려준다. props 는 해시 테이블이라 순회 순서가 선언 순서와 무관하고, Luau 구현
-- (버전, Roblox 와 CLI)에 따라서도 달라질 수 있다. 그대로 순회하면 같은 스키마가 환경마다 다른 문자열을
-- 내므로, 문자열화할 때는 항상 이 순서를 쓴다. (테이블 생성자는 선언 순서를 남기지 않으므로 정렬뿐이다)
const function sortedKeys(props: { [string]: Base.TSchema }): { string }
    const keys: { string } = {}
    for key in props do
        table.insert(keys, key)
    end
    table.sort(keys)
    return keys
end

const function luauBuilder(schema: TObject<any>): string
    const items: { string } = {}
    for _, key in sortedKeys(schema.props) do
        local ident = if Util.isValidIdent(key) then key else `["{Util.escapeLuauString(key)}"]`
        table.insert(items, `{ident}: {defaultUntypedNamespace:luauBuild(schema.props[key])}`)
    end

    return `\{ {table.concat(items, ", ")} }`
end

const function formatter(schema: TObject<any>): string
    const items: { string } = {}
    for _, key in sortedKeys(schema.props) do
        local ident = if Util.isValidIdent(key) then key else `["{Util.escapeLuauString(key)}"]`
        table.insert(items, `{ident}: {defaultUntypedNamespace:format(schema.props[key])}`)
    end

    return `TObject<\{ {table.concat(items, ", ")} }>`
end

const function runtimeTypeChecker(schema: TObject<any>, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "table" then
        return function()
            return `table expected for {formatter(schema)}, but got {ty}`
        end
    end

    const checkedKeys: { [string]: true | nil } = {}
    for key: any, innerValue: any in value do
        if typeof(key) ~= "string" then
            return function()
                return "objects cannot have non-string keys"
            end
        end

        const valueSchema = schema.props[key]
        if not valueSchema then
            continue
        end
        checkedKeys[key] = true

        const check = defaultUntypedNamespace:runtimeTypeCheck(valueSchema, innerValue)
        if check then
            return function()
                return `object property '{key}' type check failed.\n{Util.indent(check())}`
            end
        end
    end

    for key, innerSchema in schema.props do
        if not checkedKeys[key] and not defaultUntypedNamespace:canBeNil(innerSchema) then
            return function()
                return `required object property '{key}' not exist.`
            end
        end
    end

    return nil
end

-- 확장된 TObject 의 경우 상위 TObject 와 공변적(Covariance) 관계를 가지기 때문에
-- 이 경우도 적합한 타입으로 선택되어야합니다. 따라서 확장 TObject 에 대한 에러 처리는 제약 조건 확인입니다.
const function runtimeConstraintChecker(schema: TObject<any>, value: any): (() -> string)?
    for key: any, innerValue: any in value do
        const valueSchema = schema.props[key]
        if not valueSchema then
            if not schema.allowUnknownProps then
                return function()
                    -- Property '{key}' is not allowed
                    return `object property '{key}' is not allowed`
                end
            end
            -- 허용된 미지의 프로퍼티는 대응하는 스키마가 없으므로 제약 검사 대상이 아닙니다
            continue
        end

        const check = defaultUntypedNamespace:runtimeConstraintCheck(valueSchema, innerValue)
        if check then
            return function()
                return `object property '{key}' constraint check failed.\n{Util.indent(check())}`
            end
        end
    end

    return nil
end

const function inspectInner(schema: TObject<any>): { Base.TSchema }
    const innerSchemas: { Base.TSchema } = {}

    for _, inner in schema.props do
        table.insert(innerSchemas, inner)
    end

    return innerSchemas
end

return Base.TypeDefFactory("Object", Object, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    inspectInner = inspectInner,
})
