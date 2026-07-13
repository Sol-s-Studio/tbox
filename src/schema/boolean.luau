--!strict

const Base = require("../base")
const Types = require("../types")

export type TBoolean = {} & Base.TSchema & Types.InnerType<boolean>
export type TBooleanOptions = Types.Merge<{}, Base.TSchemaOptions>

const function Boolean(options: TBooleanOptions?): TBoolean
    options = options or ({} :: TBooleanOptions)
    return Base.SchemaFactory<<TBoolean>>("Boolean", options, {})
end

const function luauBuilder(schema: TBoolean): string
    return "boolean"
end

const function formatter(schema: TBoolean): string
    return "TBoolean"
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

return Base.TypeDefFactory("Boolean", Boolean, {
    runtimeTypeChecker = runtimeTypeChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
