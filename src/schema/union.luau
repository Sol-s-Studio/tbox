--!strict

const Base = require("../base")
const Types = require("../types")
const Util = require("../util")
const defaultUntypedNamespace = require("../registry").defaultUntypedNamespace

export type TUnion<Tuple> =
    { components: Tuple }
    & Base.TSchema
    & Types.InnerType<TupleTypeToUnion<Types.StaticTuple<Types.GetTupleType<Tuple>>>>
-- export type TUnion<Components...> = { components: Types.Tuple<Components...> } & Base.TSchema & Types.InnerType<
--     TupleTypeToUnion<Types.StaticTuple<Types.TupleType<Components...>>>
-- >
export type TUnionOptions = Types.Merge<{}, Base.TSchemaOptions>

type function TupleTypeToUnion(tupty: type): type
    const head: { type } = tupty:parameters().head or {}
    return types.unionof(table.unpack(head))
end

-- Components... 를 사용할 수 있지만, new solver 는 infer 중에 부작용이 있으므로
-- 명시적으로 요소를 추출합니다. (만약 pack 에 대해 infer 된다면 다른 후행 함수 인자 요소가 오염됩니다)
-- const function Union<Components...>(tup: Types.Tuple<Components...>, options: TUnionOptions?): TUnion<Components...>
const function Union<Tuple>(tup: Tuple, options: TUnionOptions?): TUnion<Tuple>
    options = options or ({} :: TUnionOptions)
    return Base.SchemaFactory<<TUnion<Tuple>>>("Union", options, {
        components = tup,
    })
end

const function luauBuilder(schema: TUnion<any>): string
    const items = table.create(schema.components.n) :: { string }
    for key = 1, schema.components.n do
        const inner = schema.components[key]
        table.insert(items, `({defaultUntypedNamespace:luauBuild(inner)})`)
    end

    return `{table.concat(items, " | ")}`
end

const function formatter(schema: TUnion<any>): string
    const items = table.create(schema.components.n) :: { string }
    for key = 1, schema.components.n do
        const inner = schema.components[key] :: Base.TSchema
        table.insert(items, defaultUntypedNamespace:luauBuild(inner))
    end

    return `TUnion<{table.concat(items, ", ")}>`
end

const function runtimeTypeChecker(schema: TUnion<any>, value: any): (() -> string)?
    const errList = table.create(schema.components.n) :: { () -> string }

    for key = 1, schema.components.n do
        const inner = schema.components[key] :: Base.TSchema
        const check = defaultUntypedNamespace:runtimeTypeCheck(inner, value)
        if not check then
            return nil
        end
        table.insert(errList, check)
    end

    return function()
        const mappedError = table.create(schema.components.n) :: { string }
        for index, check in errList do
            table.insert(mappedError, `branch {index}: {check()}`)
        end
        const errStr = table.concat(mappedError, "\n")
        return `union value check failed. value did not match any of the union members.\n{Util.indent(errStr)}`
    end
end

const function runtimeConstraintChecker(schema: TUnion<any>, value: any): (() -> string)?
    for key = 1, schema.components.n do
        const inner = schema.components[key] :: Base.TSchema
        const check = defaultUntypedNamespace:runtimeTypeCheck(inner, value)

        if not check then
            return defaultUntypedNamespace:runtimeConstraintCheck(inner, value)
        end
    end
    return nil
end

const function inspectInner(schema: TUnion<any>): { Base.TSchema }
    const innerSchemas: { Base.TSchema } = {}

    for key = 1, schema.components.n do
        const inner = schema.components[key] :: Base.TSchema
        table.insert(innerSchemas, inner)
    end

    return innerSchemas
end

const function canBeNil(schema: TUnion<any>): boolean
    for key = 1, schema.components.n do
        const inner = schema.components[key] :: Base.TSchema
        if defaultUntypedNamespace:canBeNil(inner) then
            return true
        end
    end
    return false
end

return Base.TypeDefFactory("Union", Union, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
    inspectInner = inspectInner,
})
