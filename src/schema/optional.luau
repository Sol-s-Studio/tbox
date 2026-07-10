--!strict

const SchemaFactory = require("../base")
const Types = require("../types")
const defaultUntypedNamespace = require("../registry").defaultUntypedNamespace
const Util = require("../util")

export type TOptional<InnerSchema> =
    { inner: InnerSchema }
    & SchemaFactory.TSchema
    & Types.InnerType<Types.Static<InnerSchema>?>
export type TOptionalOptions = Types.Merge<{}, SchemaFactory.TSchemaOptions>

const function Optional<InnerSchema>(target: InnerSchema, options: TOptionalOptions?): TOptional<InnerSchema>
    options = options or ({} :: TOptionalOptions)
    return SchemaFactory<<TOptional<InnerSchema>>>("Optional", options, { inner = target })
end

const function luauBuilder(schema: TOptional<any>): string
    return `({defaultUntypedNamespace:luauBuild(schema.inner)})?`
end

const function formatter(schema: TOptional<any>): string
    return `TOptional<{defaultUntypedNamespace:format(schema.inner)}>`
end

const function canBeNil(_schema: TOptional<any>): boolean
    return true
end

const function runtimeTypeChecker(schema: TOptional<any>, value: any): (() -> string)?
    if value == nil then
        return nil
    end

    const innerCheck = defaultUntypedNamespace:runtimeTypeCheck(schema.inner, value)
    if not innerCheck then
        return nil
    end

    return function()
        return `optional value is not nil, but its inner type check failed.\n{Util.indent(innerCheck())}`
    end
end

const function runtimeConstraintChecker(schema: TOptional<any>, value: any): (() -> string)?
    if value == nil then
        return nil
    end
    return defaultUntypedNamespace:runtimeConstraintCheck(schema.inner, value)
end

return {
    typeName = "Optional",
    factoryFunc = Optional,
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
}
