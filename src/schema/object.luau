--!strict

const SchemaFactory = require("../base")
const Types = require("../types")
const Util = require("../util")
const defaultUntypedNamespace = require("../registry").defaultUntypedNamespace

export type TObject<Props> =
    { props: { [string]: SchemaFactory.TSchema }, allowUnknownProps: boolean? }
    & SchemaFactory.TSchema
    & Types.InnerType<Types.TObjectPropsFlatten<Props>>
export type TObjectOptions = Types.Merge<{
    allowUnknownProps: boolean?,
}, SchemaFactory.TSchemaOptions>

const function Object<Props>(props: { [string]: SchemaFactory.TSchema } & Props, options: TObjectOptions?): TObject<Props>
    options = options or ({} :: TObjectOptions)
    return SchemaFactory<<TObject<Props>>>("Object", options, {
        props = props,
        allowUnknownProps = options.allowUnknownProps,
    })
end

const function luauBuilder(schema: TObject<any>): string
    const items: { string } = {}
    for key, inner in schema.props do
        local ident = if Util.isVaildIdent(key) then key else `["{Util.escapeLuauString(key)}"]`
        table.insert(items, `{ident}: {defaultUntypedNamespace:luauBuild(inner)}`)
    end

    return `\{ {table.concat(items, ", ")} }`
end

const function formatter(schema: TObject<any>): string
    const items: { string } = {}
    for key, inner in schema.props do
        local ident = if Util.isVaildIdent(key) then key else `["{Util.escapeLuauString(key)}"]`
        table.insert(items, `{ident}: {defaultUntypedNamespace:format(inner)}`)
    end

    return `TObject<\{ {table.concat(items, ", ")} }>`
end

const function canBeNil(_schema: TObject<any>): boolean
    return false
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

const function runtimeConstraintChecker(schema: TObject<any>, value: any): (() -> string)?
    if not schema.allowUnknownProps then
        for key: any, _innerValue in value do
            const valueSchema = schema.props[key]
            if not valueSchema then
                return function()
                    -- Property '{key}' is not allowed
                    return `object property '{key}' is not allowed`
                end
            end
        end
    end

    return nil
end

return {
    typeName = "Object",
    factoryFunc = Object,
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
}
