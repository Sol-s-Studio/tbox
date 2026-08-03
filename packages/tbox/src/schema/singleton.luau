--!strict

const Base = require("../base")
const Types = require("../types")
const Util = require("../util")

export type TSingleton<ConstType> =
    { value: ConstType, valueType: string }
    & Base.TSchema
    & Types.InnerType<ConstType>
    & Types.NamedType<"Singleton">
export type TSingletonOptions = Types.Merge<{}, Base.TSchemaOptions>

type function CheckIsSingleton(ty: type): type
    if not ty:is("singleton") then
        print(
            'Singleton<T>(T, ...): singleton typebox target \'T\' must be singleton type.\nNote: You must cast runtime value to singleton type. try Singleton("test" :: "test")'
        )
        return types.never
    end
    return ty
end

const function Singleton<ConstType>(singleton: ConstType, options: TSingletonOptions?): TSingleton<CheckIsSingleton<ConstType>>
    local valueType = typeof(singleton)
    options = options or ({} :: TSingletonOptions)
    return Base.SchemaFactory<<TSingleton<ConstType>>>("Singleton", options, {
        value = singleton,
        valueType = valueType,
    })
end

const function luauBuilder(schema: TSingleton<any>): string
    if schema.valueType == "string" then
        return `"{Util.escapeLuauString(schema.value :: string)}"`
    elseif schema.valueType == "boolean" then
        return tostring(schema.value)
    end

    return "unknown"
end

const function formatter(schema: TSingleton<any>): string
    return `TSingleton<{luauBuilder(schema)}>`
end

const function runtimeTypeChecker(schema: TSingleton<any>, value: any): (() -> string)?
    if schema.value ~= value then
        const ty = typeof(value)
        return function()
            const luau = luauBuilder(schema)
            return `{luau} expected for Singleton<{luau}>, but got {ty}`
        end
    end

    return nil
end

return Base.TypeDefFactory("Singleton", Singleton, {
    runtimeTypeChecker = runtimeTypeChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
