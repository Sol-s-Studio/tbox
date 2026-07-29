--!strict

const Base = require("../base")
const Types = require("../types")

export type TString =
    { maxLength: number?, minLength: number?, vaildUtf8Only: boolean? }
    & Base.TSchema
    & Types.InnerType<string>
    & Types.NamedType<"String">
export type TStringOptions = Types.Merge<
    { maxLength: number?, minLength: number?, vaildUtf8Only: boolean? },
    Base.TSchemaOptions
>

const function String(options: TStringOptions?): TString
    options = options or ({} :: TStringOptions)
    return Base.SchemaFactory<<TString>>("String", options, {
        maxLength = options.maxLength,
        minLength = options.minLength,
        vaildUtf8Only = options.vaildUtf8Only,
    })
end

const function luauBuilder(schema: TString): string
    return "string"
end

const function formatter(schema: TString): string
    return "TString"
end

const function runtimeTypeChecker(schema: TString, value: any): (() -> string)?
    const ty = typeof(value)
    if ty ~= "string" then
        return function()
            return `string expected, but got {ty}`
        end
    end
    return nil
end

const function runtimeConstraintChecker(schema: TString, value: string): (() -> string)?
    const len = #value
    if schema.maxLength and len > schema.maxLength then
        return function()
            return `string too long. maximum allowed length is {schema.maxLength} characters`
        end
    end
    if schema.minLength and len < schema.minLength then
        return function()
            return `string too short. minimum allowed length is {schema.minLength} characters`
        end
    end
    if schema.vaildUtf8Only then
        const utf8Len = utf8.len(value)
        if utf8Len == nil then
            return function()
                return `invalid UTF-8 string`
            end
        end
    end
    return nil
end

return Base.TypeDefFactory("String", String, {
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
})
