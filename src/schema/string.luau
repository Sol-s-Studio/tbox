--!strict

const SchemaFactory = require("../base")
const Types = require("../types")

export type TString = { maxLength: number?, minLength: number? } & SchemaFactory.TSchema & Types.InnerType<string>
export type TStringOptions = Types.Merge<{ maxLength: number?, minLength: number? }, SchemaFactory.TSchemaOptions>

const function String(options: TStringOptions?): TString
    options = options or ({} :: TStringOptions)
    return SchemaFactory<<TString>>("String", options, {
        maxLength = options.maxLength,
        minLength = options.minLength,
    })
end

const function luauBuilder(schema: TString): string
    return "string"
end

const function formatter(schema: TString): string
    return "TString"
end

const function canBeNil(schema: TString): boolean
    return false
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
    return nil
end

return {
    typeName = "String",
    factoryFunc = String,
    runtimeTypeChecker = runtimeTypeChecker,
    runtimeConstraintChecker = runtimeConstraintChecker,
    luauBuilder = luauBuilder,
    formatter = formatter,
    canBeNil = canBeNil,
}
