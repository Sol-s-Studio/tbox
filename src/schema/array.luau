--!strict

-- Inner must not be nil

const Base = require("../base")
const Types = require("../types")
const Util = require("../util")
const defaultUntypedNamespace = require("../registry").defaultUntypedNamespace

export type TArray<InnerSchema> =
    { maxItems: number?, minItems: number?, inner: InnerSchema }
    & Base.TSchema
    & Types.InnerType<{ Types.Static<InnerSchema> }>
export type TArrayOptions = Types.Merge<
    { maxItems: number?, minItems: number?, numericIndexOnly: boolean? },
    Base.TSchemaOptions
>

const function Array<InnerSchema>(target: InnerSchema, options: TArrayOptions?): TArray<InnerSchema>
    options = options or ({} :: TArrayOptions)

    return Base.SchemaFactory<<TArray<InnerSchema>>>("Array", options, {
        inner = target,
        maxItems = options.maxItems,
        minItems = options.minItems,
        numericIndexOnly = options.numericIndexOnly,
    })
end

const function luauBuilder(schema: TArray<any>): string
    return `\{{defaultUntypedNamespace:luauBuild(schema.inner)}}`
end

const function formatter(schema: TArray<any>): string
    return `TArray<{defaultUntypedNamespace:format(schema.inner)}>`
end

const function runtimeTypeChecker(schema: TArray<any>, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "table" then
        return function()
            return `table expected for {formatter(schema)}, but got {ty}`
        end
    end

    for key: any, innerValue: any in value do
        if typeof(key) ~= "number" then
            return function()
                return "arrays cannot have non-numeric keys"
            end
        end
        const check = defaultUntypedNamespace:runtimeTypeCheck(schema.inner, innerValue)
        if check then
            return function()
                return `array value inner type check failed at index {key}.\n{Util.indent(check())}`
            end
        end
    end

    return nil
end

const function runtimeConstraintChecker(schema: TArray<any>, value: { any }): (() -> string)?
    const len = #value
    if schema.maxItems and len > schema.maxItems then
        return function()
            return `array too long. maximum allowed length is {schema.maxItems}`
        end
    end
    if schema.minItems and len < schema.minItems then
        return function()
            return `array too short. minimum allowed length is {schema.minItems}`
        end
    end

    for key, innerValue: any in value do
        const check = defaultUntypedNamespace:runtimeConstraintCheck(schema.inner, innerValue)
        if check then
            return function()
                return `array value inner constraint check failed at index {key}.\n{Util.indent(check())}`
            end
        end
    end

    return nil
end

const function inspectInner(schema: TArray<any>): { Base.TSchema }?
    return { schema.inner }
end

return Base.TypeDefFactory("Array", Array, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    inspectInner = inspectInner,
})
