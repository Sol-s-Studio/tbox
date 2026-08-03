--!strict

const Base = require("../../base")
const Types = require("../../types")
const defaultUntypedNamespace = require("../../registry").defaultUntypedNamespace
const Object = require("./object")

export type TMerge<Tuple> =
    {
        components: Tuple,
        __check: CheckMergeable<Types.StaticNameTuple<Types.GetTupleType<Tuple>>>,
    }
    & Object.TObjectProps
    & Base.TSchema
    & Types.InnerType<Types.MergeInner<Types.StaticTuple<Types.GetTupleType<Tuple>>>>
    & Types.NamedType<"Merge">
export type TMergeOptions = Types.Merge<{}, Object.TObjectOptions, Base.TSchemaOptions>

type function CheckMergeable(tupty: type): type
    if tupty:is("any") then
        return types.any
    end

    const head: { type } = tupty:parameters().head or {}
    local hasError = false

    for _, ty in head do
        if not ty:is("singleton") then
            print("unexpected tbox error. TMerge input tuple is not vaild")
            hasError = true
            continue
        end

        if not (ty:value() == "Object" or ty:value() == "Merge") then
            print(`{ty:value()} cannot be merged`)
            hasError = true
            continue
        end
    end

    if hasError then
        return types.never
    end

    return types.any
end

const function Merge<Tuple>(tuple: Tuple, options: TMergeOptions?): TMerge<Tuple>
    options = options or ({} :: TMergeOptions)
    const props: { [string]: Base.TSchema } = {}

    for idx = 1, (tuple :: Types.Tuple<Base.TSchema>).n do
        const mergeTarget: Base.TSchema & Object.TObjectProps = (tuple :: Types.Tuple<Base.TSchema>)[idx]
        for key, schema in mergeTarget.props do
            props[key] = schema
        end
    end

    return Base.SchemaFactory<<TMerge<Tuple>>>("Merge", options, {
        props = props,
        components = tuple,
        allowUnknownProps = options.allowUnknownProps,
    })
end

const function formatter(schema: TMerge<any>): string
    const items: { string } = {}
    for idx = 1, schema.components.n do
        const inner: Base.TSchema = schema.components[idx]
        table.insert(items, defaultUntypedNamespace:format(inner))
    end

    return `TMerge<{table.concat(items, ", ")}>`
end

return Base.TypeDefFactory("Merge", Merge, {
    runtimeTypeChecker = Object.runtimeTypeChecker,
    runtimeConstraintChecker = Object.runtimeConstraintChecker,
    luauBuilder = Object.luauBuilder,
    formatter = formatter,
    inspectInner = Object.inspectInner,
})
