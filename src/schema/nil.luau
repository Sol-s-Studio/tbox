--!strict

const Base = require("../base")
const Types = require("../types")

export type TNil = {} & Base.TSchema & Types.InnerType<nil>
export type TNilOptions = Types.Merge<{}, Base.TSchemaOptions>

const function Nil(options: TNilOptions?): TNil
    options = options or ({} :: TNilOptions)
    return Base.SchemaFactory<<TNil>>("Nil", options, {})
end

const function luauBuilder(schema: TNil): string
    return "nil"
end

const function formatter(schema: TNil): string
    return "TNil"
end

const function canBeNil(_schema: TNil): boolean
    return true
end

const function runtimeTypeChecker(schema: TNil, value: any): (() -> string)?
    if value ~= nil then
        const ty = typeof(value)
        return function()
            return `nil expected, but got {ty}`
        end
    end
    return nil
end

return Base.TypeDefFactory("Nil", Nil, {
    runtimeTypeChecker = runtimeTypeChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
})
