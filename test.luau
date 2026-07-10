--!strict

const Type = require("./src/index")

const box = Type.Object({
    hello = Type.String(),
    world = Type.Number(),
    ["1aaa"] = Type.Number(),
})

const check = Type:runtimeTypeCheck(box, { hello = "", world = 1 })
print(check and check())
-- INFO: required object property '1aaa' not exist.

const check2 = Type:runtimeTypeCheck(box, { hello = "", world = "" })
print(check2 and check2())
-- INFO: object property 'world' type check failed.
-- INFO:   number expected, but got string

const TypedArray = Type.Array(
    Type.Boolean({
        title = "metadata for document and type generation",
    }),
    {
        maxItems = 3, -- Length limited array
    }
)
const check3 = Type:runtimeTypeCheck(TypedArray, { true, false, 1 })
print(check3 and check3())
-- INFO: array value inner type check failed at index 3.
-- INFO:   boolean expected, but got number

const check4 = Type:runtimeConstraintCheck(TypedArray, { true, false, true, true })
print(check4 and check4())
-- INFO: array too long. maximum allowed length is 3

-- to static luau type
function test(body: Type.Static<typeof(box)>) end
test({
    ["1aaa"] = 1, -- if remove, Table type ... not compatible with type '{ ['1aaa']: number, hello: string, world: number }'
    --               because the former is missing field
    hello = "", -- hello = 2, TypeError: Expected this to be 'string', but got 'number' Luau1000
    world = 1,
})

-- make luau type string
print(Type:luauBuild(box))
-- INFO: { hello: string, ["1aaa"]: number, world: number }

-- format typebox for debugging
print(Type:format(box))
-- INFO: TObject<{ hello: TString, ["1aaa"]: TNumber, world: TNumber }>
