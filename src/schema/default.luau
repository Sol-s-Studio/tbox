--!strict

const SchemaFactory = require("../base")
const Types = require("../types")
const Util = require("../util")
const defaultUntypedNamespace = require("../registry").defaultUntypedNamespace

export type TDefault<InnerSchema> =
    { inner: InnerSchema, default: Types.Static<InnerSchema> }
    & SchemaFactory.TSchema
    & Types.InnerType<Types.Static<InnerSchema>?>
export type TDefaultOptions = Types.Merge<{}, SchemaFactory.TSchemaOptions>

const function formatter(schema: TDefault<any>): string
    return `TDefault<{defaultUntypedNamespace:format(schema.inner)}>`
end

const function Default<InnerSchema>(
    target: InnerSchema,
    default: Types.Static<InnerSchema>,
    options: TDefaultOptions?
): TDefault<InnerSchema>
    options = options or ({} :: TDefaultOptions)

    const schema = SchemaFactory<<TDefault<InnerSchema>>>("Default", options, {
        default = default,
        inner = target,
    })

    const typeCheck = defaultUntypedNamespace:runtimeTypeCheck(target, default)
    if typeCheck then
        error(`{formatter(schema)} default value type check failed\n{Util.indent(typeCheck())}`)
    end
    const constraintCheck = defaultUntypedNamespace:runtimeConstraintCheck(target, default)
    if constraintCheck then
        error(`{formatter(schema)} default value constraint check failed\n{Util.indent(constraintCheck())}`)
    end

    return schema
end

const function luauBuilder(schema: TDefault<any>): string
    return `({defaultUntypedNamespace:luauBuild(schema.inner)})?`
end

const function canBeNil(_schema: TDefault<any>): boolean
    return true
end

const function runtimeTypeChecker(schema: TDefault<any>, value: any): (() -> string)?
    if value == nil then
        return nil
    end
    return defaultUntypedNamespace:runtimeTypeCheck(schema.inner, value)
end

const function runtimeConstraintChecker(schema: TDefault<any>, value: any): (() -> string)?
    if value == nil then
        return nil
    end
    return defaultUntypedNamespace:runtimeConstraintCheck(schema.inner, value)
end

return {
    typeName = "Default",
    factoryFunc = Default,
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
}
