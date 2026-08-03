--!strict

const Base = require("../base")
const Types = require("../types")

export type TUnsafe<T> =
    { luauType: string, canBeNil: boolean }
    & Base.TSchema
    & Types.InnerType<T>
    & Types.NamedType<"Unsafe">
export type TUnsafeOptions = Types.Merge<{ luauType: string?, canBeNil: boolean? }, Base.TSchemaOptions>

const function Unsafe<T>(options: TUnsafeOptions?): TUnsafe<T>
    options = options or ({} :: TUnsafeOptions)
    return Base.SchemaFactory<<TUnsafe<T>>>("Unsafe", options, {
        luauType = options.luauType or "unknown",
        canBeNil = options.canBeNil or false,
    })
end

const function luauBuilder(schema: TUnsafe<any>): string
    return schema.luauType
end

const function formatter(schema: TUnsafe<any>): string
    return `TUnsafe<{schema.luauType}>`
end

const function canBeNil(schema: TUnsafe<any>): boolean
    return schema.canBeNil
end

const function runtimeTypeChecker(schema: TUnsafe<any>, value: any): (() -> string)?
    return nil
end

return Base.TypeDefFactory("Unsafe", Unsafe, {
    runtimeTypeChecker = runtimeTypeChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
})
