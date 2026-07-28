--!strict

const Base = require("../base")
const Types = require("../types")

export type TAny = {} & Base.TSchema & Types.InnerType<any> & Types.NamedType<"Any">
export type TAnyOptions = Types.Merge<{}, Base.TSchemaOptions>

const function Any(options: TAnyOptions?): TAny
    options = options or ({} :: TAnyOptions)
    return Base.SchemaFactory<<TAny>>("Any", options, {})
end

const function luauBuilder(schema: TAny): string
    return "any"
end

const function formatter(schema: TAny): string
    return "TAny"
end

const function canBeNil(_schema: TAny): boolean
    return true
end

const function runtimeTypeChecker(schema: TAny, value: any): (() -> string)?
    return nil
end

return Base.TypeDefFactory("Any", Any, {
    runtimeTypeChecker = runtimeTypeChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
})
