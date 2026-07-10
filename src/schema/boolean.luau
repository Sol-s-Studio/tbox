--!strict

const SchemaFactory = require("../base")
const Types = require("../types")

export type TBoolean = {} & SchemaFactory.TSchema & Types.InnerType<boolean>
export type TBooleanOptions = Types.Merge<{}, SchemaFactory.TSchemaOptions>

const function Boolean(options: TBooleanOptions?): TBoolean
    options = options or ({} :: TBooleanOptions)
    return SchemaFactory<<TBoolean>>("Boolean", options, {})
end

const function luauBuilder(schema: TBoolean): string
    return "boolean"
end

const function formatter(schema: TBoolean): string
    return "TBoolean"
end

const function canBeNil(_schema: TBoolean): boolean
    return false
end

const function runtimeTypeChecker(schema: TBoolean, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "boolean" then
        return function()
            return `boolean expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TBoolean, value: boolean): (() -> string)?
    return nil
end

return {
    typeName = "Boolean",
    factoryFunc = Boolean,
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
}
