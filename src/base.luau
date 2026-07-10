--!strict

-- TSchema: InnerType<?>
export type TSchema = {
    id: string?,
    description: string?,
    title: string?,
    tag: string,
}
export type TSchemaOptions = {
    id: string?,
    description: string?,
    title: string?,
}
local function SchemaFactory<Schema, Base>(tag: string, options: TSchemaOptions?, base: Base): Schema
    options = options or ({} :: TSchemaOptions)
    const anyBase = base :: any
    anyBase.tag = tag
    anyBase.id = options.id
    anyBase.description = options.description
    anyBase.title = options.title
    return anyBase :: Schema
end

return SchemaFactory
