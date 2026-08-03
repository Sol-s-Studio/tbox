--!strict

-- Inner must not be nil

const Base = require("../base")
const Types = require("../types")
const Util = require("../util")
const defaultUntypedNamespace = require("../registry").defaultUntypedNamespace

export type TMap<KeySchema, ValueSchema> =
    { maxItems: number?, minItems: number?, key: KeySchema, value: ValueSchema }
    & Base.TSchema
    & Types.InnerType<{ [Types.Static<KeySchema>]: Types.Static<ValueSchema> }>
    & Types.NamedType<"Map">
export type TMapOptions = Types.Merge<{ maxItems: number?, minItems: number? }, Base.TSchemaOptions>

const function Map<KeySchema, ValueSchema>(key: KeySchema, value: ValueSchema, options: TMapOptions?): TMap<KeySchema, ValueSchema>
    options = options or ({} :: TMapOptions)

    return Base.SchemaFactory<<TMap<KeySchema, ValueSchema>>>("Map", options, {
        key = key,
        value = value,
        maxItems = options.maxItems,
        minItems = options.minItems,
    })
end

const function luauBuilder(schema: TMap<any, any>): string
    return `\{ [{defaultUntypedNamespace:luauBuild(schema.key)}]: {defaultUntypedNamespace:luauBuild(schema.value)} }`
end

const function formatter(schema: TMap<any, any>): string
    return `TMap<{defaultUntypedNamespace:format(schema.key)}, {defaultUntypedNamespace:format(schema.value)}>`
end

const function runtimeTypeChecker(schema: TMap<any, any>, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "table" then
        return function()
            return `table expected for {formatter(schema)}, but got {ty}`
        end
    end

    for key: any, innerValue: any in value do
        const keyCheck = defaultUntypedNamespace:runtimeTypeCheck(schema.key, key)
        if keyCheck then
            return function()
                return `map key type check failed.\n{Util.indent(keyCheck())}`
            end
        end

        const valueCheck = defaultUntypedNamespace:runtimeTypeCheck(schema.value, innerValue)
        if valueCheck then
            return function()
                return `map value type check failed at index {tostring(key)}.\n{Util.indent(valueCheck())}`
            end
        end
    end

    return nil
end

const function runtimeConstraintChecker(schema: TMap<any, any>, value: { [any]: any }): (() -> string)?
    local len = 0
    for key: any, innerValue: any in value do
        const keyCheck = defaultUntypedNamespace:runtimeConstraintCheck(schema.key, key)
        if keyCheck then
            return function()
                return `map key constraint check failed.\n{Util.indent(keyCheck())}`
            end
        end

        const valueCheck = defaultUntypedNamespace:runtimeConstraintCheck(schema.value, innerValue)
        if valueCheck then
            return function()
                return `map value constraint check failed at index {tostring(key)}.\n{Util.indent(valueCheck())}`
            end
        end

        len += 1
    end

    if schema.maxItems and len > schema.maxItems then
        return function()
            return `map too big. maximum allowed length is {schema.maxItems}`
        end
    end
    if schema.minItems and len < schema.minItems then
        return function()
            return `map too small. minimum allowed length is {schema.minItems}`
        end
    end

    return nil
end

const function inspectInner(schema: TMap<any, any>): { Base.TSchema }?
    return { schema.key, schema.value }
end

return Base.TypeDefFactory("Map", Map, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    inspectInner = inspectInner,
})
