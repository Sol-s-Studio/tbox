--!strict

const SchemaFactory = require("../base")
const Types = require("../types")

export type TAny = {} & SchemaFactory.TSchema & Types.InnerType<any>
export type TAnyOptions = Types.Merge<{}, SchemaFactory.TSchemaOptions>

const function Any(options: TAnyOptions?): TAny
    options = options or ({} :: TAnyOptions)
    return SchemaFactory<<TAny>>("Any", options, {})
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

const function runtimeConstraintChecker(schema: TAny, value: any): (() -> string)?
    return nil
end

return {
    typeName = "Any",
    factoryFunc = Any,
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
}
