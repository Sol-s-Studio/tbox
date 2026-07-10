--!strict

const SchemaFactory = require("../base")
const Types = require("../types")
const Util = require("../util")

export type TSingleton<ConstType> =
    { value: ConstType, valueType: string }
    & SchemaFactory.TSchema
    & Types.InnerType<ConstType>
export type TSingletonOptions = Types.Merge<{}, SchemaFactory.TSchemaOptions>

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
    return SchemaFactory<<TSingleton<ConstType>>>("Singleton", options, {
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

const function canBeNil(schema: TSingleton<any>): boolean
    return false
end

const function runtimeTypeChecker(schema: TSingleton<any>, value: any): (() -> string)?
    if schema.value ~= value then
    end
    const ty = typeof(value)
    if ty ~= schema.valueType then
        return function()
            const luau = luauBuilder(schema)
            return `{luau} expected for Singleton<{luau}>, but got {ty}`
        end
    end

    return nil
end

const function runtimeConstraintChecker(schema: TSingleton<any>, value: any): (() -> string)?
    return nil
end

return {
    typeName = "Singleton",
    factoryFunc = Singleton,
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
}
