--!strict

const SchemaFactory = require("../base")
const Types = require("../types")

export type TUnsafe<T> = { luauType: string, canBeNil: boolean } & SchemaFactory.TSchema & Types.InnerType<T>
export type TUnsafeOptions = Types.Merge<{ luauType: string?, canBeNil: boolean? }, SchemaFactory.TSchemaOptions>

const function Unsafe<T>(options: TUnsafeOptions?): TUnsafe<T>
    options = options or ({} :: TUnsafeOptions)
    return SchemaFactory<<TUnsafe<T>>>("Unsafe", options, {
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

const function runtimeConstraintChecker(schema: TUnsafe<any>, value: any): (() -> string)?
    return nil
end

return {
    typeName = "Unsafe",
    factoryFunc = Unsafe,
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
}
